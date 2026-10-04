---
name: odoo_trainer
description: "Design and run small-audience (max ~10 people) Odoo trainings that comply with the French QUALIOPI quality referential. Use this whenever the user is preparing an Odoo training/formation session, a training program sheet, a prerequisite/positioning questionnaire, a convention de formation, or training slide decks for Odoo — especially when QUALIOPI, Digital League, Digital League Academy, or formation professionnelle compliance is mentioned. Also trigger on requests to build Odoo training slides with Marp or PlantUML, or to check whether a training program satisfies QUALIOPI indicators, even if the user doesn't name QUALIOPI explicitly (e.g. 'I need to prep a training for a customer', 'build me the prerequisite quiz for this Odoo session')."
version: 0.1.0
metadata:
  status: work-in-progress — scope will keep expanding, see Roadmap section
  related_skills: [marp, plantuml, odoo-opensource-developper, odoo-oca-developer]
---

# Odoo Trainer

Helps design and deliver small-audience Odoo trainings (≤10 people per session) that hold up against the French **QUALIOPI** quality referential. First facilitator/partner is **Digital League Auvergne-Rhône-Alpes**, through their Academy (https://www.digital-league.org/formations) — their prerequisite-questionnaire methodology is the reference pattern for positioning learners.

This skill is intentionally scoped to what's solid today. The user will define cost/proposal/e-learning requirements later — see **Roadmap** at the bottom for what's explicitly not built yet. Don't invent functionality beyond what's described here just because it would be "nice to have."

## Why QUALIOPI shapes every artifact here

QUALIOPI isn't a style guide — it's a certification audited against 32 indicators across 7 critères, each with a "niveau attendu" and concrete proof examples. Building the right paperwork *as the training is designed*, rather than reconstructing it before an audit, is the whole point of this skill. `references/qualiopi-referentiel.md` has the condensed, indicator-by-indicator breakdown; consult it whenever unsure which artifact an indicator needs.

**Important nuance to check with the user before assuming full scope:** if the Odoo trainer delivers under Digital League's own Qualiopi certification (as sous-traitant) rather than holding its own OF certification, many indicators shift to being Digital League's responsibility, not the trainer's (each indicator in the reference file has a "Sous-traitance" clause). Ask which contractual role applies if it isn't already clear — it changes how much paperwork this skill needs to produce.

## Workflow for building one training

1. **Clarify the training basics** — cible (target audience), objectifs, prérequis, durée, tarif, modalités (présentiel/distance/mixte), lieu. These feed directly into the program info sheet and are the raw material every other artifact reuses. Don't let this stay vague — QUALIOPI indicateur 5 treats vague objectives as a *non-conformité majeure*, not a minor one.

2. **Produce the program info sheet.** Covers QUALIOPI indicateurs 1, 5, 6, 9 in one document:
   - Intitulé, cible, prérequis (explicitly state "aucun prérequis" if none — silence isn't acceptable per the referential's glossary)
   - Objectifs opérationnels et évaluables
   - Durée, dates, horaires, lieu, modalités d'accès et délais
   - Tarif
   - Méthodes mobilisées et modalités d'évaluation
   - Accessibilité aux personnes en situation de handicap (state the actual accommodation process, even if the honest answer today is "contact the trainer, case-by-case")

3. **Build the prerequisite/positioning questionnaire** following the Digital League pattern in `references/digital-league-prerequisite-questionnaire.md`. Pull cible/prérequis from the program sheet — never invent new ones at this stage. Always include the two mandatory questions (attentes + motivation). This satisfies indicateur 8.

4. **Draft the convention de formation** from `references/convention-formation-template.md`, filling every bracketed field. This is the contractual + financial proof for several indicators at once (5, 8, 9, 17). Keep the effectif table at ≤10 rows — that's the format this skill targets; if a request would push past that, flag it to the user rather than silently building for a bigger cohort.

5. **Build the slide deck.** Don't reimplement slide tooling here — this skill orchestrates, the `marp` and `plantuml` skills do the mechanics:
   - Content structure (module of the training program, sequenced per the objectifs from step 2) → **Marp**-flavored Markdown, converted via the `marp` skill.
   - Any architecture/process/workflow diagram inside the deck (e.g. an Odoo module's data flow, an approval workflow being taught) → **PlantUML**, rendered via the `plantuml` skill, then embedded as an image in the Marp deck.
   - Keep slide content traceable back to the objectifs opérationnels from the program sheet — an audit can ask to see that content matches announced objectives (indicateur 6/7).

6. **Plan the evaluation loop.** QUALIOPI indicateurs 11, 30, 31, 32 all hinge on this:
   - **Évaluation à chaud**: short feedback form at session end (satisfaction + perceived acquisition of objectives).
   - **Évaluation à froid**: a delayed follow-up (weeks later) checking real application — schedule it, don't just mention it exists.
   - A place to log complaints/aléas and how they were resolved (even a simple running note satisfies indicateur 31 if it's actually used).
   - A place to log what changed in the program *because of* feedback (indicateur 32 — the loop only counts if it's closed).

7. **For sessions ≥2 days**, also produce a light engagement/anti-dropout checklist (indicateur 12) — who follows up if someone goes quiet, and when.

## Program info sheet template

```markdown
# [Intitulé de la formation]

**Public visé (cible)** : [...]
**Prérequis** : [... ou "Aucun prérequis"]
**Objectifs opérationnels et évaluables** :
- [...]
**Durée** : [...]  **Dates** : [...]  **Horaires** : [...]
**Lieu / modalités** : [présentiel|distance|mixte — adresse ou plateforme]
**Délai d'accès** : [durée estimée entre demande et début de prestation]
**Tarif** : [...]
**Méthodes mobilisées** : [...]
**Modalités d'évaluation** : [positionnement à l'entrée / évaluation à chaud / évaluation à froid]
**Accessibilité PSH** : [process d'aménagement, contact référent]
**Contact** : [...]
```

## Working with the reference files

- `references/qualiopi-referentiel.md` — the condensed 32-indicator table; check this whenever unsure what proof an indicator needs, or whether it even applies (sous-traitance clauses).
- `references/digital-league-prerequisite-questionnaire.md` — the positioning-questionnaire methodology and mandatory questions, with a worked Odoo-adaptation example.
- `references/convention-formation-template.md` — the fillable contract template with bracketed fields.

Don't paraphrase these from memory once loaded — they contain field names and thresholds (e.g. the ≥1200-word indicator table, exact bracket-field names in the convention) that are easy to get subtly wrong by re-deriving instead of reading.

## Roadmap — not yet built

The user explicitly deferred these; don't build them unprompted, but be ready to pick this section up when asked:

- **Cost management and commercial proposals**, generated from an **Odoo survey** module (for needs-analysis / questionnaire data collection) plus supporting documents. No pricing model, template, or automation exists yet beyond the flat unit-cost × headcount fields in the convention template.
- **Odoo eLearning app** (https://www.odoo.com/fr_FR/app/elearning) as a possible delivery/tracking platform — evaluation of whether to use it hasn't happened; don't assume it's in scope until the user confirms.
- Aggregate reporting across sessions (e.g. rolling satisfaction/abandon rates for indicateur 2) — currently per-session only.
