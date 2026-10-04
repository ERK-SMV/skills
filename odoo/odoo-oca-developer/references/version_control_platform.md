# OCA Version Control Platform (VCP) — architecture reference

Source: [OCA/version-control-platform](https://github.com/OCA/version-control-platform/tree/18.0) (branch `18.0`, author Dixmit). Use this as the architectural starting point for the next app (git tag management) — it is the closest existing OCA codebase for "import/track data from git hosting platforms into Odoo," even though **it does not implement tags today** (see §5).

## 1. What it actually does

VCP imports git repository activity (branches, pull/merge requests, comments, reviews, contributors) from hosting platforms (currently GitHub) into Odoo for reporting/analytics, and can shallow-clone branches locally to run static-analysis "rules" (e.g. `cloc`) against them. It is **not** a release/tag manager — there is no `vcp.tag` model anywhere in the repo.

## 2. Module layout & dependency chain

```
vcp_management  (base: hosts, platforms, repositories, branches, requests, reviews, rule engine — depends: base)
  └── vcp_git      (adds git clone/fetch via GitPython — depends: vcp_management; external: GitPython)
        └── vcp_github  (GitHub API sync — depends: vcp_git; external: github3.py, markdown)
  └── vcp_odoo     (extracts Odoo module/version/author/dependency data from cloned branches — depends: vcp_management)
  └── vcp_portal   (glue: expose VCP data on portal)
  └── vcp_website  (glue: expose VCP data on website/partner pages)
```

Each `vcp_git`/`vcp_github`-style module **extends** (`_inherit`) the base models from `vcp_management` rather than defining new ones — the base module stays host-agnostic, and each integration module bolts on the kind-specific implementation. This is the pattern to copy for a new hosting backend (e.g. GitLab) or a new capability (tags).

## 3. Core data model (`vcp_management`)

| Model | Role |
|---|---|
| `vcp.host.type` | Defines a *kind* of host: `code` (dispatch key, e.g. `"github"`) and `code_kind` (git protocol family, e.g. `"git"`). |
| `vcp.host` | A concrete host, e.g. `github.com` or a self-hosted GitLab. Has `type_id`. Provides cached `_get_user()` / `_get_organization()` upsert helpers (`@tools.ormcache`). |
| `vcp.platform` | One organization/account on a host (e.g. the `OCA` GitHub org). Holds API keys (`vcp.platform.key`), scheduling flags, `local_path` (computed from a configurable `source_code_local_path`), and the repo-wide `rule_ids`. |
| `vcp.repository` | A repo under a platform. Tracks stats (stars/forks/watchers), `fetch_branch_pattern`, scheduling flags, `local_path`, `rule_ids` (can override the platform's). |
| `vcp.branch` | A **branch name**, deduplicated **per platform** (not per repo) — `unique(name, platform_id)`, created lazily via `platform._get_branch(name)` (ormcache + get-or-create). |
| `vcp.repository.branch` | Join model: one row per (repository, branch). Holds `last_commit`, computed `local_path` (`{repository.local_path}/{branch.name}`), its own `rule_ids`/`override_parent_rules`, and drives the actual `_download_code()` + rule processing. |
| `vcp.request` / `vcp.review` / `vcp.comment` | Pull/merge requests and their reviews/comments, for contribution analytics. |
| `vcp.rule` + `vcp.rule.information.mixin` | Generic "processing rule" engine (see §6). |

**Rule model → local_path composition**: `platform.local_path = {source_path}/{platform.id}`, `repository.local_path = {platform.local_path}/{repository.name}`, `repository_branch.local_path = {repository.local_path}/{branch.name}`. `source_path` resolves from (in order) the `vcp_management.source_code_local_path` system parameter, the `source_code_local_path` odoo-bin config option, or the `SOURCE_CODE_LOCAL_PATH` env var.

## 4. The kind-dispatch extensibility pattern

Every place that needs host-specific behavior stores a short string (`platform.kind`, related through `host_id.type_id.code`, or `code_kind` for the git-protocol family) and dynamically dispatches to `_method_<kind>`:

```python
# vcp_management/models/vcp_platform.py
def update_information(self):
    self.ensure_one()
    getattr(self, f"_update_information_{self.kind}")()

# vcp_management/models/vcp_repository_branch.py
code_kind = self.repository_id.platform_id.host_id.type_id.code_kind
getattr(self, f"_download_code_{code_kind}")(local_path)
```

Adding a new backend means adding a new `_inherit`-ed method suffixed with your `kind`/`code_kind` value in your own module — no change to the base module, no big if/elif chain. **Reuse this exact pattern** for a tags module: e.g. `vcp.repository.branch._download_code_git` (already git-specific) is the template; a parallel `vcp.repository.tag._download_code_git` would look almost identical.

## 5. Git integration (`vcp_git`) — and the tag gap

```python
# vcp_git/models/vcp_repository_branch.py
import git

class VcpRepositoryBranch(models.Model):
    _inherit = "vcp.repository.branch"

    def _download_code_git(self, local_path):
        try:
            repo = git.Repo(local_path)
            for remote in repo.remotes:
                if remote.url == self.repository_id._get_git_url():
                    remote.fetch(self.branch_id.name)
                    repo.git.reset("--hard", f"{remote.name}/{self.branch_id.name}")
                    break
        except git.exc.InvalidGitRepositoryError:
            repo = git.Repo.clone_from(
                self.repository_id._get_git_url(),
                local_path,
                branch=self.branch_id.name,
                depth=1,
            )
```

Uses [GitPython](https://gitpython.readthedocs.io/), shallow clones (`depth=1`), and re-fetches + hard-resets on subsequent syncs instead of re-cloning. `_get_git_url()` is itself dispatched (`vcp.platform._get_git_url_<kind>` — e.g. `_get_git_url_github` in `vcp_github`, building an authenticated HTTPS URL from the platform's API key).

**There is no `vcp.tag` or `vcp.repository.tag` model, and no `_download_code_git` variant for tags.** For a git-tag-management app, the natural extension mirrors §3/§4 exactly:

- `vcp.tag` (name, `platform_id`, unique per platform — copy `vcp.branch`).
- `vcp.repository.tag` (join: `repository_id`, `tag_id`, `commit_sha`, `local_path`, maybe `annotated`/`message`/`tagger`/`created_at` — copy `vcp.repository.branch`, drop the rule-processing bits unless you want cloc-per-tag too).
- A `_download_code_git` on `vcp.repository.tag`: GitPython's `clone_from(..., branch=tag_name, depth=1)` works for tags exactly as it does for branches (git treats both as refs), but a shallow **fetch** of a specific tag on an already-cloned repo needs `remote.fetch(f"refs/tags/{tag_name}:refs/tags/{tag_name}")` (a plain `remote.fetch(tag_name)` does not reliably pull a new tag the way it pulls a branch head) — test this before assuming parity with the branch code above.
- If you need to *list* a repo's tags (not just clone one), that's `repo.tags` in GitPython after a full/`--tags` fetch, or the hosting platform's API (`vcp_github` already wraps `github3.py` — `repository.tags()` is the GitHub equivalent of its existing branch-listing sync).
- Reuse the existing `_cron_update_branches` / `scheduled_branch_update` pattern on `vcp.repository` for an analogous `_cron_update_tags` / `scheduled_tag_update`.

## 6. Rule engine (generic processing, e.g. cloc)

`vcp.rule` defines `branch_pattern` (regex) + `paths` (a `pathspec`/gitignore-style pattern) + `rule_type` (currently only `"cloc"`). `vcp.repository.branch._get_rules()` merges its own `rule_ids` with the repository's (unless `override_parent_rules`), matches `branch_pattern` against the branch name, then calls `rule._process_rule(record, parameters)` → dispatches to `_process_rule_<rule_type>`. The `cloc` implementation shells out (`subprocess.check_output(["cloc", "--by-file", "--json", local_path])`), filters matched files with `pathspec`, and stores results via the `vcp.rule.information.mixin` (`rule_information_ids`, one row per `(rule, record)`). Failures are caught per-record in `process_rules()`, stored in `rule_failure_msg`, and don't abort the batch (`self.env.cr.savepoint()` per record + `self.env.registry.clear_cache()` on rollback to avoid stale-cache surprises from a partially-created Odoo module).

This same engine could run a tag-specific rule (e.g. "does this tag's manifest version match the tag name") by tagging a new `rule_type` and matching against `vcp.repository.tag` instead of `vcp.repository.branch`.

## 7. Cron-driven sync pattern

Both `vcp.platform` and `vcp.repository` use a `scheduled_*_update: Boolean` (computed+stored, defaulting from the parent) + a `*_update_date: Datetime` "last processed" marker + a `_cron_update_*(limit)` classmethod-style batch method that `search()`s the oldest-updated eligible records, processes them, and stamps the date — a simple, resumable work-queue without a dedicated job-queue module. Copy this for a tag-sync cron rather than inventing a new mechanism.

## 8. Manifests / external dependencies (for your own `depends`/`external_dependencies`)

```python
# vcp_management
"depends": ["base"],
"external_dependencies": {"python": ["pathspec"], "bin": ["cloc"], "deb": ["cloc"]},

# vcp_git
"depends": ["vcp_management"],
"external_dependencies": {"python": ["GitPython"]},

# vcp_github
"depends": ["vcp_git"],
"external_dependencies": {"python": ["github3.py", "markdown"]},
```

A git-tags module would sensibly depend on `vcp_git` (or your own equivalent base+git modules) the same way `vcp_github` does, rather than reimplementing git plumbing.
