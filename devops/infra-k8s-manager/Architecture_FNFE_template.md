---
marp: true
theme: default
paginate: true
footer: 'FNFA - Architecture & CI/CD - Akretion   Sébastien Maurines'
backgroundColor: #fff
color: #333

<!-- INCIPIT
Tous les fichiers à utiliser pour monter les présentations sont dans ~/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/infra-k8s-manager/presentation

Toutes les schemas sont sur le format plantuml


INPUT et OUT de BASE
~/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/infra-k8s-manager/presentation$ Architecture_FNFE_template.md => fichier d'instruction à ne pas changer
Architecture_FNFE_to-transform.md => fichier output à transformer avec la l'incrementation du nom de fichier DD-MM-YYYY_HH-MM-SS

-->



1/ proposer à Cyrille un unzip façon comme Connecting Europe ==> https://github.com/ConnectingEurope/eInvoicing-EN16931/blob/master/zip-release.sh 

2/ Expliquer l'interêt d'une CI/CD pour pouvoir automatiser l'incrémentation de fichier.
Expliquer le role d'une CI et de la CD indépendement l'une de l'autre.
Expliquer l'intérêt des artifact.

4/ expliquer les limites d'Actions de GITHUB.COM dans sa version gratuite notamment avec le Docker qui est proposé nativement

-->

<!-- Le point de vue général de cette présentation est d'explication au client pourquoi il est pertinent pour lui d'apopter une architect -->

---


# **FNFE Architecture actuel**

L'architecture est définit ici: /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/factur-x-validator_UBL-CDAR-CTC/AUDIT-VPS-FNFE/audit-complet-vps.sh

Avec l'aide de /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/infra-k8s-manager/SKILL.md
Le Markdown: à reprendre si nécessaire est ici

Voici l'image PLANTUML à reprendre ici si nécessaire:


---

## **Sommaire**

1. **🏗️ Architecture FNFE existante** *(Devis n°68)*
2. **⚡ Intérêt de la CI/CD avec GitLab** *(vs GitHub Actions)*
3. **🚀 Proposition d'hébergement Akretion**

---

## **Partie 1**
## 🏗️ Architecture FNFE existante

### **Contexte actuel du client**

![Architecture Existante FNFE](images/fnfa_existant.png)
*Architecture VPS sans Docker - Odoo + PostgreSQL + py3o + verapdf*

---

## **Partie 2**
## ⚡ Intérêt de la CI/CD avec GitLab

### **Comparatif : GitLab CI/CD vs GitHub Actions**
 | **Critère**               | **GitLab CI/CD** (On-Premise) | **GitHub Actions** | **Recommandation** |
 |--------------------------|-------------------------------|-------------------|-------------------|
 | **Intégration native**   | ✅ Parfait avec GitLab        | ✅ Native          | GitLab           |
 | **Repository privé**     | ✅ Illimité                   | ❌ Limité (2000 min/mois gratuit) | GitLab |
 | **Self-hosted runners**  | ✅ Facile à déployer           | ✅ Possible        | ⚖️ Équivalent    |
 | **Sécurité**             | ✅ Contrôle total             | ⚠️ Dépend de GitHub | **GitLab** |
 | **Coût**                 | ✅ Gratuit (self-hosted)       | ❌ Payant à l'usage | **GitLab** |
 | **Artifacts**            | ✅ Stockage illimité          | ⚠️ 2Go gratuit    | **GitLab** |
 | **Pipeline as Code**     | ✅ `.gitlab-ci.yml`            | ✅ YAML           | ⚖️ Équivalent    |
 | **Intégration Odoo**     | ✅ Optimisé pour Odoo          | ⚠️ Générique      | **GitLab** |
 | **Support FNFE**         | ✅ Compatible `fnfempe/France_RFE` | ✅ Compatible | ⚖️ OK |

---

### **Pipeline GitLab pour FNFE : `fnfempe/France_RFE`**

```yaml
# Exemple de .gitlab-ci.yml pour FNFE
stages:
  - test
  - build
  - deploy

python_tests:
  stage: test
  image: python:3.10-odoo
  script:
    - pip install -r requirements.txt
    - pytest tests/unit/ -v
    - pytest tests/integration/ -v

validation_tests:
  stage: test
  script:
    - python scripts/validate_business_rules.py

build_image:
  stage: build
  image: docker\:stable
  script:
    - docker build -t fnfe\:latest .
    - docker push fnfe\:latest

deploy_prod:
  stage: deploy
  script:
    - kubectl apply -f k8s/
  when: manual