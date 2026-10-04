# Facturation en Belgique

## Mentions obligatoires (facture papier ou électronique)

- Date d'émission et numéro de facture (séquence unique, ininterrompue, par année ou en continu)
- Nom/dénomination et adresse du fournisseur et du client
- Numéro d'entreprise (BCE) du fournisseur, précédé de **BE** si numéro de TVA
- Numéro de TVA du client (obligatoire en B2B ; si le client est assujetti)
- Date de l'opération (livraison du bien / prestation du service) si différente de la date de facture
- Description claire de la nature, quantité et prix unitaire de chaque bien/service — **trois mentions distinctes, comme en France : une description correcte ne dispense pas d'indiquer séparément quantité et prix unitaire**
- Taux(s) de TVA appliqué(s), base imposable par taux, montant de TVA par taux
- Mention de l'exonération le cas échéant, avec la base légale (ex : autoliquidation intracommunautaire, exportation)
- Date d'exigibilité / conditions de paiement

## Facturation électronique — obligation Peppol (B2B domestique)

- **Depuis le 1er janvier 2026**, la facturation électronique structurée est **obligatoire pour les transactions B2B domestiques** entre assujettis établis en Belgique (hors quelques exceptions : assujettis en franchise, faillites, certains régimes particuliers — **à revérifier au cas par cas**).
- Format et réseau imposés : **Peppol BIS Billing 3.0** via le réseau **Peppol**, qui nécessite un accès via un **Access Point** (fournisseur de service Peppol) — la simple PDF envoyée par e-mail ne suffit plus pour les flux concernés.
- Toute entreprise assujettie doit donc :
  1. S'enregistrer sur le réseau Peppol via un Access Point (souvent fourni par le logiciel de facturation/comptabilité).
  2. Être capable d'émettre **et** de recevoir des factures structurées Peppol.
  3. Adapter sa numérotation et ses processus de validation en conséquence.
- **Incitant fiscal** : déduction fiscale majorée temporaire pour les investissements des PME/indépendants dans des logiciels et services de facturation électronique (période couvrant 2024-2027, taux de déduction majoré — **vérifier le taux exact et les conditions en vigueur avant de le mentionner en conseil**).
- Le **PPF belge/Peppol** ne joue pas le rôle d'une plateforme centrale de dépôt comme peut l'envisager la France — c'est un réseau d'échange décentralisé (4-corner model) : chaque entreprise passe par son propre Access Point, qui achemine la facture jusqu'à l'Access Point du destinataire.

## Notes de crédit (avoirs)

- Mêmes mentions obligatoires que la facture, avec référence explicite à la facture initiale corrigée (numéro, date) et motif de la correction.
- Numérotation dans une séquence propre ou clairement identifiable comme note de crédit.

## Conservation

- Durée légale de conservation des factures : **10 ans** (délai fiscal général belge, aligné sur le délai de prescription en matière de TVA/impôts directs) — à confirmer selon le type de document et le régime applicable.
- Conservation sous forme garantissant l'authenticité de l'origine, l'intégrité du contenu et la lisibilité (contrôles internes documentés ou signature électronique / EDI structuré type Peppol).

## Points de vigilance

- Ne pas confondre l'obligation belge (Peppol, dès 01/2026, B2B domestique) avec le calendrier français (PDP/PA, 2026-2027) — les deux réformes sont indépendantes, avec des réseaux et formats différents (Peppol pur en Belgique vs écosystème PDP/PPF en France, bien que Peppol soit aussi un des standards possibles côté français).
- Le numéro de TVA du client est obligatoire sur les factures B2B belges bien avant la réforme 2026 — ne pas présenter cela comme une nouveauté (contrairement à la France où le SIREN client devient obligatoire seulement avec la réforme).
