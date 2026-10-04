# Convention de formation professionnelle — fillable template

Source pattern: modèle Quali-Santé, structured per articles L.6353-2 et R.6353-1 du Code du travail. Use this as the base contract between the Odoo training organism and the beneficiary company. Fill every bracketed field before sending; nothing here should ship with placeholders still in it.

```markdown
# CONVENTION DE FORMATION PROFESSIONNELLE
Selon l'article L.6353-2 et R. 6353-1 du Code du travail

## Entre les soussignés

**L'organisme de formation** (dénomination et adresse) : [NOM_OF], [ADRESSE_OF]
Enregistré sous le numéro de déclaration d'activité : [NUMERO_DECLARATION_ACTIVITE]
Auprès de (DREETS) : [DREETS_REGION]
Représenté par : [NOM_REPRESENTANT_OF]

**Et l'entreprise** (raison sociale, dénomination et adresse) : [NOM_ENTREPRISE], [ADRESSE_ENTREPRISE]
Représenté par : [NOM_REPRESENTANT_ENTREPRISE]

## L'organisme de formation organise l'action de formation suivante

- **Intitulé** : [INTITULE_FORMATION]
- **Nature de l'action** (art. L.6313-1 code du travail) : [NATURE_ACTION]
- **Dates de l'action** : [DATES]
- **Durée et horaires** : [DUREE_HORAIRES]
- **Lieu** (adresse complète) : [LIEU]
- **Modalités de déroulement** : [MODALITES]
- **Moyens** (supports pédagogiques, noms/titres des formateurs) : [MOYENS]
- **Type de formation** (présentiel / distance / mixte) : [TYPE]
- **Modalités d'évaluation** : [MODALITES_EVALUATION]

## Effectif de l'action de formation

L'entreprise bénéficiaire s'engage à assurer la présence des personnes suivantes (max 10 stagiaires pour ce format) :

| Nom Prénom | Fonction | Coordonnées |
|---|---|---|
| [NOM_1] | [FONCTION_1] | [CONTACT_1] |

**Moyen de contrôle du suivi** : [MOYEN_CONTROLE — ex. feuille d'émargement, suivi LMS]

## Conditions financières

L'entreprise s'engage à acquitter les frais suivants :

| Coût unitaire HT | Nombre de stagiaires | Total HT |
|---|---|---|
| [COUT_UNITAIRE] € | [NB_STAGIAIRES] | [TOTAL_HT] € |

- Soit un total de : [TOTAL_HT] € HT
- TVA (fournir le formulaire 3511 en cas d'exonération) : [TVA] €
- **MONTANT TOTAL** : [TOTAL_TTC] € TTC
- Dont contribution éventuelle des financeurs publics : [CONTRIBUTION_FINANCEUR] €

## En cas d'inexécution partielle ou totale

[DETAIL_OBLIGATIONS_FINANCIERES_RECIPROQUES — clause de dédommagement / remboursement]

La présente convention prend effet à compter de sa signature.

Fait en double exemplaire à : [LIEU_SIGNATURE]
Le : [DATE_SIGNATURE]

**Pour l'entreprise bénéficiaire** : [NOM_QUALITE_SIGNATAIRE_ENTREPRISE] — Signature, cachet

**Pour l'organisme de formation** : [NOM_QUALITE_SIGNATAIRE_OF] — Signature, cachet
```

## Notes for this skill

- This convention is the QUALIOPI-relevant proof for several indicators at once (5, 8, 9, 17 in particular) — keep a signed copy per session in the training's evidence folder.
- The 10-stagiaire cap for this skill's target format should be reflected in the effectif table — don't let it silently grow past what the room/format was designed for.
- Financial terms here are intentionally minimal (flat unit cost × headcount). Real cost modeling / proposal generation from Odoo survey and documents is **not yet built** — see the Roadmap section in `SKILL.md`. For now, fill the pricing fields manually or from whatever spreadsheet the user already uses.
