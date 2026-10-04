# PCMN — Plan Comptable Minimum Normalisé

Base légale : Arrêté royal du 12 septembre 1983 (comptabilité et comptes annuels des entreprises), tel que modifié. Toute entreprise peut détailler le PCMN en sous-comptes mais doit pouvoir s'y raccrocher (raccordement obligatoire pour le dépôt à la Centrale des bilans).

## Structure par classe

| Classe | Intitulé |
|--------|----------|
| 0 | Droits et engagements hors bilan (garanties reçues/données, biens de tiers détenus...) |
| 1 | Fonds propres, provisions et impôts différés, dettes à plus d'un an |
| 2 | Frais d'établissement, actifs immobilisés (incorporels, corporels, financiers), créances à plus d'un an |
| 3 | Stocks et commandes en cours d'exécution |
| 4 | Créances et dettes à un an au plus (clients, fournisseurs, TVA à récupérer/à payer, rémunérations et charges sociales) |
| 5 | Placements de trésorerie et valeurs disponibles (banques, caisse) |
| 6 | Charges (achats, services et biens divers, rémunérations, amortissements, charges financières, charges exceptionnelles, impôts) |
| 7 | Produits (chiffre d'affaires, production stockée, produits financiers, produits exceptionnels) |

Symétrie 6/7 : chaque sous-classe de charge (60-66) a un pendant en produit (70-76) ; 68/78 = transferts aux/des réserves immunisées ; 69/79 = affectations et prélèvements.

## Points de repère fréquents

- **Classe 4 — TVA** : compte 411 (TVA à récupérer), compte 451 (TVA à payer). Le détail par déclaration périodique doit permettre le contrôle croisé avec Intervat.
- **Classe 6 — comptes 62x** : rémunérations, charges sociales, pensions — distinction dirigeant d'entreprise / personnel.
- **Comptes 100-101 (capital)** : depuis le CSA (2019), la SRL n'a plus de capital minimum légal mais un "apport" avec plan financier obligatoire — l'appellation comptable "capital" est remplacée par "apport" dans les nouveaux statuts, à vérifier selon la date de constitution.
- **Réserve de liquidation (compte 132)** : mécanisme propre aux PME belges pour distribuer les bénéfices à moindre précompte mobilier à terme (5 ans) — voir [impots-be.md](impots-be.md).

## Schémas des comptes annuels

Le formulaire de dépôt (schéma complet, abrégé ou micro) dépend de la taille de l'entreprise (critères cumulés : total bilan, chiffre d'affaires, effectif ETP — seuils indexés périodiquement, **à vérifier sur nbb.be avant toute qualification**). Dépôt via la Centrale des bilans de la BNB, en principe dans les 30 jours de l'approbation par l'assemblée générale et au plus tard 7 mois après la date de clôture de l'exercice.

Les avis de la **Commission des Normes Comptables (CBN/CNC)** font autorité sur les questions d'interprétation du droit comptable belge (traitement des subsides, leasing, provisions, etc.) — consulter cnc-cbn.be pour tout cas non couvert ici.
