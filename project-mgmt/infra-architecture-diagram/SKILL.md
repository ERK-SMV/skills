---
name: infra-architecture-diagram
description: "Architecture diagrams and stakeholder decks for the erk-infra OVH/RKE2 environment, combining PlantUML, the dark-SVG architecture-diagram skill, and Marp."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [architecture, diagrams, plantuml, marp, presentation, infra, kubernetes, rke2, gitlab, odoo]
    related_skills: [architecture-diagram, plantuml, marp, concept-diagrams]
---

# Infra Architecture Diagram Skill

Produces diagrams and presentations describing the `2.erk-infra` environment — a self-managed RKE2 Kubernetes cluster running Odoo (ERK/FNFE), ArgoCD, and AI tooling (Hermes and friends) — by picking the right tool for the job, and packaging the result into a slide deck when the audience needs a walkthrough rather than a static image.

This skill doesn't reimplement rendering itself — it routes to `plantuml`, the bundled `architecture-diagram`, and `marp`, and carries the environment facts needed to describe this specific infrastructure correctly instead of generic placeholders.

## Environment facts (use these, don't invent placeholders)

- **Cluster**: self-managed RKE2 on OVH VPS nodes (`v1.30.2+rke2r1` as of 2026-07), managed via `mgmt.infra.flows.cab`.
- **GitLab, not GitHub**: primary repo is `gitlab.akretion.com/akretion/fnfe`. Prefer `glab` for any GitLab operation; don't default to `gh`/GitHub terminology in diagrams or docs.
- **Namespaces**: AI tooling (Hermes, PlantUML, Marp, n8n) lives in `ai-tools`. Each Odoo instance gets its own namespace (e.g. `fnfe18-front`, `odoo18-erk-test`).
- **GitOps**: ArgoCD deploys from `k8s/infra/argocd/apps/*.yaml` but does NOT auto-discover new app manifests just because they're committed — each `Application` needs one manual `kubectl apply` (no app-of-apps pattern here). Worth calling out explicitly in any diagram of the deploy path.
- **Odoo**: separate instances for ERK and FNFE, each with its own Postgres and, where needed, a `py3o`/`kwkhtmltopdf` print pipeline.

## Choosing a tool

| Need | Tool | Why |
|---|---|---|
| Precise UML (sequence, class, component, state) | `plantuml` skill → `plantuml-service` (curl, direct IP) | Correct UML syntax/semantics, not a free-hand approximation |
| Stakeholder-facing infra/cloud topology sketch | `architecture-diagram` skill (bundled) | Purpose-built dark SVG/HTML design system for exactly this; see that skill for the full color palette, component styling, and `templates/template.html` reference |
| Turning either into a walkthrough deck | `marp` skill → bundled `marp-cli` via Hermes's own Node runtime | Converts Markdown (can embed the PNG/SVG/HTML produced above) into an HTML slide deck |

Don't make one tool do all three jobs: don't hand-draw SVG for a sequence diagram (use `plantuml`), and don't try to force PlantUML's own visual style into the `architecture-diagram` dark theme — each tool's native output is the correct one for its content type.

## Current Status (2026-07-29)

- **PlantUML Service**: ✅ Running at `10.43.94.102` (DNS issue: `plantuml-service.ai-tools.svc.cluster.local` not resolving)
- **Marp CLI**: ✅ Installed v4.5.0, HTML conversion working (PDF/PPTX requires browser)
- **Architecture-Diagram**: ✅ Bundled skill available (no changes needed)

## Typical workflow

Mirrors the 5-phase flow already documented in this project's `infra-k8s-manager` skill:

1. **Design** — PlantUML for precise component/sequence relationships, or the `architecture-diagram` dark theme for a broader infra/cloud overview.
2. **Development** — as the real infra changes (new namespace, new ArgoCD app, new Odoo instance), keep the diagram in sync rather than letting it drift.
3. **Documentation** — commit the rendered diagram (PNG/SVG/HTML) alongside the relevant manifests, or push it to the GitLab wiki (`gitlab.akretion.com/akretion/fnfe/-/wikis`).
4. **Presentation** — if the audience needs a walkthrough rather than a static diagram, feed the diagram + explanatory text into the `marp` skill to produce a slide deck (HTML export only — PDF/PPTX need Chromium, not currently installed in the Hermes pod).
5. **Review** — share via GitLab merge request or wiki page, not by pasting raw PlantUML/SVG source into chat.

## Notes

- All PlantUML/Marp commands run from inside the Hermes pod itself — `plantuml-service` via `curl` using direct IP `10.43.94.102` (DNS resolution issue confirmed), `marp-cli` via `/root/.hermes/node/bin/marp` (Node.js v22.22.1 installed). See the `plantuml` and `marp` skills for exact, tested commands.
- Secrets/tokens never belong in a diagram — component names and data flows only, per this project's own security notes (see `infra-k8s-manager` skill).
