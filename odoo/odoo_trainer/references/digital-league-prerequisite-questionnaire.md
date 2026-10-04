# Prerequisite / positioning questionnaire — Digital League Academy pattern

Source: "Guide — Construire un questionnaire de prérequis", Digital League Auvergne-Rhône-Alpes (https://www.digital-league.org/formations). Digital League is the first facilitator partner for these Odoo trainings — their Academy expects prerequisite questionnaires built this way before a session is scheduled. This directly implements QUALIOPI indicateur 8 (see `qualiopi-referentiel.md`).

## Why this exists

Two purposes, both required:
1. **Evaluate the real level** of registered learners ahead of time, so the trainer isn't surprised on day one.
2. **Adapt the session** to the actual audience, so it runs smoothly for both learners and trainer.

## Build sequence

1. Pull the **cible** (target audience) and **prérequis** (stated prerequisites) directly from the training's program sheet — don't invent new ones here, the questionnaire only *verifies* what the program already claims.
2. Write questions that test those prerequisites and confirm the audience matches the cible. Available question formats (Digital League's platform): texte libre, question réponse unique, question réponses multiples, grille de choix, score, note sur 10, auto-évaluation sur les objectifs.
3. For every QCM question, specify which answers are correct and which are wrong.
4. For every QCM question, specify the **passing score** — the threshold above which a learner is considered to already hold the prerequisite (e.g. "at least 1 correct answer out of 2").

## Mandatory questions (always include, regardless of training topic)

These two are required by the Digital League / QUALIOPI pattern on every prerequisite questionnaire, independent of subject matter:

1. **"Quelles sont vos attentes vis-à-vis de la formation ?"** — free text.
2. **"Quel est votre degré de motivation pour cette formation ?"** — numeric, 1–5 or 1–10.

## Worked example (adapt the pattern, not the content, for Odoo trainings)

Digital League's own example, for a Java developer training with "connaître les bases de la programmation" as prerequisite:

| # | Format | Question | Purpose / expected answer |
|---|--------|----------|----------------------------|
| 1 | Texte libre | Quelle est votre fonction dans l'entreprise ? | Validates the **cible** — job title should match the target audience |
| 2 | QCM | Qu'est-ce qu'une fonction en programmation ? | Tests the stated prerequisite |
| 3 | QCM | Qu'est-ce que l'héritage en programmation ? | Tests the stated prerequisite — score threshold e.g. ≥1/2 correct across Q2+Q3 |
| 4 | Note sur 10 | Auto-évaluez votre niveau de connaissance des bases de la programmation ? | Self-assessment — threshold e.g. ≥8/10 |
| + mandatory | Texte libre | Quelles sont vos attentes vis-à-vis de la formation ? | Required by pattern |
| + mandatory | Note 1–5 ou 1–10 | Quel est votre degré de motivation pour cette formation ? | Required by pattern |

## Applying this to an Odoo training

When building the questionnaire for a specific Odoo session, replace the programming-specific questions with Odoo-specific ones tied to the actual cible/prérequis of that session, for example:

- Cible = "Utilisateur métier comptabilité" / Prérequis = "Notions de comptabilité générale" → ask a QCM on débit/crédit, or a self-assessment note on comptabilité knowledge.
- Cible = "Administrateur fonctionnel Odoo" / Prérequis = "Avoir déjà utilisé Odoo en tant qu'utilisateur" → ask which Odoo modules they use day-to-day (texte libre) + a QCM on a core concept (e.g. what a "vue kanban" is).
- Cible = "Développeur Odoo" / Prérequis = "Bases Python + notions ORM" → mirror the Java example almost directly, swapping in Python/ORM questions.

Always keep the 2 mandatory questions (attentes + motivation) regardless of the topic.

## Output the questionnaire produces

A synthesis view per cohort (Digital League's platform renders one automatically) showing, per question: distribution of answers, average score, and a computed "prerequisites met / not met" flag per learner. When building this by hand (e.g. as an Odoo survey — see Roadmap in `SKILL.md`), replicate at minimum: per-learner pass/fail on the scored questions, and the free-text/motivation answers surfaced for the trainer to skim before day one.
