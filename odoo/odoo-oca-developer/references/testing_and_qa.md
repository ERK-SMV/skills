# Odoo Testing & QA Tooling

Sources: [Odoo 18.0 official testing reference](https://www.odoo.com/documentation/18.0/fr/developer/reference/backend/testing.html) · [ERK-SMV/module_git-mgmt](https://github.com/ERK-SMV/module_git-mgmt) (org's copier template, forked from `OCA/oca-addons-repo-template`) · [OCA/maintainer-quality-tools](https://github.com/OCA/maintainer-quality-tools) (archived, legacy Travis CI tooling)

## 1. Python unit tests

### File layout

Tests live in a `tests` sub-package, auto-discovered only for modules matching `test_*` **and** imported from `tests/__init__.py`:

```
your_module/
├── ...
├── tests/
│   ├── __init__.py
│   ├── test_foo.py
│   └── test_bar.py
```

```python
# tests/__init__.py
from . import test_foo, test_bar
```

A test module not imported from `tests/__init__.py` is never run. Test **methods** must start with `test_`.

### Test base classes (`odoo.tests`)

- `TransactionCase` — most common; each test method runs in the same rolled-back transaction. Provides `browse_ref`, `ref`.
- `SingleTransactionCase` — all methods in the class share **one** transaction (faster for read-heavy chained assertions).
- `HttpCase` — extends `TransactionCase`, adds `url_open`, `browser_js`, `start_tour` for HTTP/tour tests.
- `Form` — simulates the web client form view (onchange-aware) for building test records the way a user would.
- `M2MProxy` / `O2MProxy` — helpers for `Form` to manipulate one2many/many2many widgets (`add`, `remove`, `clear`, `new`, `edit`).

```python
class TestModelA(TransactionCase):
    def test_some_action(self):
        record = self.env['model.a'].create({'field': 'value'})
        record.some_action()
        self.assertEqual(record.field, expected_field_value)
```

### Tagging & selection (`odoo.tests.tagged`)

`tagged()` is a **class** decorator only (no effect on functions/methods). Subclasses of `BaseCase` (i.e. `TransactionCase`/`HttpCase`) are implicitly tagged `standard` and `at_install`.

```python
from odoo.tests import HttpCase, tagged

@tagged('-at_install', 'post_install')
class WebsiteVisitorTests(HttpCase):
    def test_create_visitor_on_tracked_page(self):
        ...
```

Special tags:
- `standard` — implicit default tag; `--test-tags` defaults to `+standard`.
- `at_install` — runs right after the module itself installs, before other modules. Implicit default.
- `post_install` — runs after **all** modules are installed. Use this for most `HttpCase`/tour tests, usually paired with `-at_install`.

A plain `unittest.TestCase` (not inheriting `BaseCase`) gets no implicit tags — tag it manually or it won't run:

```python
import unittest
from odoo.tests import tagged

@tagged('standard', 'at_install')
class SmallTest(unittest.TestCase):
    ...
```

### Running tests

`--test-enable` runs tests on install/update. `--test-tags` implies `--test-enable` and filters selection; `+`/`-` prefixes add/remove (comma-separated = OR for `+`, always excluded for `-`).

Full `--test-tags` grammar: `[-][tag][/module][:class][.method]`

```bash
odoo-bin --test-tags /sale                       # only sale module tests
odoo-bin --test-tags '/sale,-slow'                # sale tests, excluding "slow"
odoo-bin --test-tags '-standard, slow, /stock'    # non-standard: slow-tagged or stock module
odoo-bin --test-tags .test_supplier_invoice_forwarded_by_internal_user_without_supplier
odoo-bin --test-tags nice,standard                # nice OR standard
```

Modules must be installed (`-i`) or upgraded (`-u`) at least once for their tests to run.

## 2. Integration testing (tours)

Tours drive the actual web client (Python + JS together) to catch integration bugs unit tests miss.

### Test tour structure

```
your_module/
├── static/tests/tours/your_tour.js
├── tests/
│   ├── __init__.py
│   └── test_calling_the_tour.py
└── __manifest__.py
```

```python
'assets': {
    'web.assets_tests': [
        'your_module/static/tests/tours/your_tour.js',
    ],
},
```

```javascript
import tour from 'web_tour.tour';
tour.register('rental_product_configurator_tour', {
    url: '/web',
}, [
    tour.stepUtils.showAppsMenuItem(),
    {
        trigger: '.o_app[data-menu-xmlid="your_module.maybe_your_module_menu_root"]',
        isActive: ['community'],
        run: "click",
    },
]);
```

Step keys: `trigger` (required selector), `run` (`"click"`, `"fill"`, `"edit"`, `"select"`, `"hover"`, `"check"`/`"uncheck"`, `"drag_and_drop target"`, or an async function), `isActive` (desktop/mobile, community/enterprise, auto/manual), `tooltipPosition`, `content`, `timeout` (default 10000ms). The last step must leave the client in a stable state (no pending network requests).

```python
def test_your_test(self):
    self.start_tour("/web", "your_tour_name", login="admin")
```

### Onboarding tours (in-app, non-test)

Add a `data/your_tour.xml` record on `web_tour.tour` (`name` must match the JS registry name; `sequence`, `url`, `rainbow_man_message` optional) and load the JS from `web.assets_backend` instead of `web.assets_tests`. Run via user menu → **Onboarding**, or Settings → Technical → User Interface → Tours. A **Record** button on that view lets you capture a tour interactively and export it to JS.

### Debugging tours

- `self.start_tour(url, name, watch=True)` — opens a real Chrome window while the tour runs (local only).
- `self.start_tour(url, name, debug=True)` — same, fullscreen with devtools + breakpoint at tour start (`debug=assets`).
- Browser console: `odoo.startTour("tour_name")`, or append `?debug=tests` to the URL.
- Step-level: `break: true` (JS debugger at step start), `pause: true` (halt at step end, resume with `play();` in console), or a `run() { debugger; }` step.
- `--screenshots` / `--screencasts` CLI flags; on failure a PNG is auto-saved to `/tmp/odoo_tests/{db_name}/screenshots/`.

## 3. Performance testing

```python
with self.assertQueryCount(11):
    do_something()
```

`assertQueryCount` (on `BaseCase`) fails if the block issues more SQL queries than expected — use it to catch N+1 regressions. Manual query inspection: `--log-sql`.

## 4. QA tooling for OCA-style repos

### Repo scaffolding — ERK-SMV/module_git-mgmt

This is the org's actively-maintained fork of `OCA/oca-addons-repo-template`, driven by [Copier](https://github.com/copier-org/copier). It renders, per repo:

- `.pre-commit-config.yaml` (black, isort, autoflake, pyupgrade, prettier + `@prettier/plugin-xml`, eslint, flake8 + `flake8-bugbear`, pylint with `pylint-odoo`, `setuptools-odoo`, plus OCA's own `oca-fix-manifest-website` / `oca-update-pre-commit-excluded-addons` hooks)
- `.pylintrc` / `.pylintrc-mandatory` (mandatory = blocking in pre-commit; the plain `.pylintrc` extends it and adds optional/non-blocking checks meant for IDE use)
- `.flake8` (`max-line-length = 80`, `max-complexity = 16`, bugbear-enabled, ignores `E203,E501,W503` to defer to black)
- `oca_dependencies.txt`, `.travis.yml.jinja`

Bootstrap / update a repo:

```bash
pipx install copier pre-commit
copier copy https://github.com/ERK-SMV/module_git-mgmt.git some-repo
cd some-repo && pre-commit install && pre-commit run -a
git add . && git commit -am 'Hello world'

# later, to pull template updates into an existing repo:
copier update
pre-commit run || git commit -am 'Reformatted after template update'
```

`copier.yml` prompts for `odoo_version`, `repo_slug`, `repo_name`, `repo_description`, `dependency_installation_mode` (OCA vs PIP), `rebel_module_groups` (modules tested in isolated CI jobs), `include_wkhtmltopdf`.

> **Caveat:** as of the last check, this template's `copier.yml` only offers `odoo_version` choices `12.0`/`13.0`/`14.0`. Before using it to scaffold a 17.0/18.0+ repo, check whether the choices list (and the `.travis.yml.jinja` → GitHub Actions equivalent) has been extended, or use `OCA/oca-addons-repo-template` upstream directly for newer versions and port the org-specific bits back.

**Mandatory pylint-odoo checks enabled** (blocking): `api-one-deprecated`, `dangerous-default-value`, `dangerous-view-replace-wo-priority`, `duplicate-id-csv`, `duplicate-xml-record-id`, `eval-used`, `license-allowed`, `manifest-required-author`, `manifest-required-key`, `manifest-version-format`, `method-required-super`, `print-used`, `sql-injection`, `translation-required`, `xml-syntax-error`, and more — full list in [oca_conventions.md](oca_conventions.md).

### CI dependency management — OCA/maintainer-quality-tools (MQT, archived)

Superseded by GitHub Actions in current `oca-addons-repo-template`, but the **conventions it defined are still the ones OCA repos use**:

- `oca_dependencies.txt` at repo root — one dependency per line: `project_name [repository_url] [branch_name]`. Cross-repo deps get cloned and placed on the addons path after your own repo but before Odoo core.
- `UNIT_TEST="1"` — tests each module individually to catch missing manifest `depends`.
- `LINT_CHECK="1"` — isolated flake8+pylint build, skip on others with `LINT_CHECK="0"`.
- `TEST_ENABLE="0"` — install without running tests.
- Coverage auto-excludes `*_example` modules.

Modern equivalent: `OCA/oca-addons-repo-template`'s GitHub Actions workflows + the same `oca_dependencies.txt` file (the convention persists even though the runner changed from Travis to GHA).

## 5. Quick checklist for a new OCA-style module's tests

1. `tests/__init__.py` imports every `test_*.py` file.
2. Business-logic tests → `TransactionCase`, tagged implicitly `standard, at_install`.
3. Tests touching the web client / controllers → `HttpCase`, tag `@tagged('-at_install', 'post_install')`.
4. Any tour → `static/tests/tours/*.js` registered via `web_tour.tour`, loaded in `web.assets_tests`, called from a `HttpCase.start_tour`.
5. Run locally before pushing: `pre-commit run -a` (lint) then `odoo-bin --test-tags /your_module` (tests).
