---
name: odoo-opensource-developper
description: Guide for Odoo development, containerization, deployment.
user-invocable: true
allowed-tools: bash read edit write_file grep
triggers:
  - Odoo
  - Odoo 14
  - Odoo 15
  - Odoo 16
  - Odoo 17
  - Odoo 18
  - Kubernetes
  - K8s
  - RKE2
  - Docker
  - containerization
  - OpenSource
  - development
  - deployment
  - GitLab CI
  - ArgoCD
  - Factur-X
  - FNFE
  - migration
  - OpenUpgrade
  - upgrade
  - database migration
  - Odoo migration
  - version upgrade
  - migrate modules
  - migration scripts
---

# Odoo Open-Source Developer Guide

## Overview

This skill provides comprehensive guidance for **Odoo open-source development** with a focus on **containerized deployments on Kubernetes (RKE2)**. All technical details, configurations, and sensitive information are documented in the referenced README files in the docker-vps-prod-v14 and erk-infra repositories.

**Security Note:** This document contains **NO sensitive information** (IPs, passwords, tokens, SSH keys). All sensitive data is stored in the referenced README files or external secret management systems (Passbolt, K8s secrets).

---

## Repository Structure & Documentation Map

### Core Documentation Files

| Category | File | Description |
|----------|------|-------------|
| **K8s Migration (Odoo 14)** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) | Complete migration guide: VPS to K8s, architecture, tool stack (Bedrock, Docky, AK), troubleshooting |
| **Odoo 18 Template** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md) | Architecture & deployment guide for Odoo 18 ERK, GitOps flow, key configuration |
| **Odoo 18 ERK** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-erk/patches/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-erk/patches/README.md) | Patch management for external OCA modules |
| **Official Odoo Shared Template** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/real-odoo-shared-template/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/real-odoo-shared-template/) | **Team-wide Docker/Docky/K8s Odoo template** (source: [akretion/docky-odoo-template-shared@14.0](https://github.com/akretion/docky-odoo-template-shared/tree/14.0)) - Use for new Odoo projects |
| **Docky Template Shared v2** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/docky-odoo-template-shared/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/docky-odoo-template-shared/) | **Official Akretion Docky/Copier template** (source: [akretion/docky-odoo-template-shared@v2](https://github.com/akretion/docky-odoo-template-shared/tree/v2)) - Copier-based template for new projects |

### Infrastructure & Platform

| Category | File | Description |
|----------|------|-------------|
| **Cluster Provisioning** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/provisioning/Cluster-Install_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/provisioning/Cluster-Install_README.md) | OVH VPS provisioning, RKE2 HA cluster setup, application deployment |
| **DNS Management** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/provisioning/dns-mail/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/provisioning/dns-mail/) | DNS records and mail configuration for Infomaniak |

### Kubernetes & GitOps

| Category | File | Description |
|----------|------|-------------|
| **GitLab Runner** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md) | GitLab KAS setup, Kubernetes agent configuration, troubleshooting |

### Security & IAM

| Category | File | Description |
|----------|------|-------------|
| **IAM & SSO** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md) | Central OAuth/OIDC setup, GitLab as identity provider, access control matrix |
| **Passbolt Deployment** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/passbolt/passbolt-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/passbolt/passbolt-readme.md) | K8s Helm deployment, GPG/JWT key generation, secret management |

### Factur-X & Compliance

| Category | File | Description |
|----------|------|-------------|
| **FNFE Schemas** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/fnfe-schemas/FNFE_RFE_INVOICE/UBL/xsd_UBL2.1/UBL2.1_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/fnfe-schemas/FNFE_RFE_INVOICE/UBL/xsd_UBL2.1/UBL2.1_README.md) | UBL 2.1 schema documentation for electronic invoicing |
| **Validator Schemas** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/local-src/factur-x-validator_UBL-CDAR-CTC/facturx_validator/schemas/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/local-src/factur-x-validator_UBL-CDAR-CTC/facturx_validator/schemas/README.md) | Factur-X validator schema structure |
| **Validator Upgrading** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/local-src/factur-x-validator_UBL-CDAR-CTC/upgrading_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/local-src/factur-x-validator_UBL-CDAR-CTC/upgrading_README.md) | Upgrade procedures for Factur-X validator |
| **Odoo 18 Fnfe Front Patches** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/patches/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/patches/README.md) | Module patches for Fnfe front instance |

---

## Quick Reference by Topic

### 1. Odoo Containerization

**Primary Documentation:**
- Odoo 14 FNFE: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md)
- Odoo 18 ERK: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md)
- **Official Odoo Shared Template**: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/real-odoo-shared-template/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/real-odoo-shared-template/) (Docker/Docky/K8s template for all Odoo projects)

**Key Concepts:**
- **Bedrock**: Minimal Python venv scaffold (acsone/odoo-bedrock)
- **Docky**: Akretion's Docker image structuring convention
- **AK (git-aggregator)**: Multi-repo clone and merge tool
- **Multi-stage Docker builds**: base → thisproject → test/prod/dev
- **Odoo Shared Template**: Standardized Docker/Docky/Kubernetes scaffold for all team Odoo projects (see `real-odoo-shared-template/`)
- **Copier**: Jinja2-based project templating tool (used by docky-odoo-template-shared)
- **Docky Template Shared v2**: Official Akretion template repository (see `docky-odoo-template-shared/`)

**Quick Start:**
```bash
# For Odoo 18 ERK
cd odoo18-erk
ak clone && ak build
docker build --target test --tag odoo18-erk:test .

# For Odoo 14 FNFE
cd docker-vps-prod-v14
# See odoo-k8s-readme.md for detailed steps
```

**Docky Template Shared v2 (Official Akretion Template):**
> **Location**: `app/second-brain/odoo-opensource-developper/docky-odoo-template-shared/`
>
> **Source**: [akretion/docky-odoo-template-shared@v2](https://github.com/akretion/docky-odoo-template-shared/tree/v2)
>
> **Purpose**: Official Akretion Copier-based template for Odoo projects. Uses Jinja2 templating with support for Odoo 14.0-19.0.
>
> **Template Features**:
> - Copier-based project scaffolding
> - Multi-version support (14.0, 15.0, 16.0, 17.0, 18.0, 19.0)
> - Docker Compose configurations (dev, ci, prod, test)
> - Docky v2 convention
> - GitLab CI/CD integration
> - Kubernetes-ready
> - PostgreSQL, Redis, and service containers
> - Startup entrypoint scripts (000_set_base_url, 004_open_upgrade, etc.)
> - Backup/restore scripts
>
> **Usage**:
> ```bash
> # Create new project from official template
> copier copy https://github.com/akretion/docky-odoo-template-shared.git my-project
> # Or use the local copy
> copier copy /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/docky-odoo-template-shared my-project
> cd my-project
> # Answer the copier questions (project_name, branch_name, etc.)
> # Then initialize with ak
> cd my-project/odoo
> ak clone && ak build
> ```

**Official Odoo Shared Template:**
> **Location**: `app/second-brain/odoo-opensource-developper/real-odoo-shared-template/`
> 
> **Source**: [akretion/docky-odoo-template-shared@14.0](https://github.com/akretion/docky-odoo-template-shared/tree/14.0) (Copier template)
> 
> **Purpose**: Standardized Docker/Docky/Kubernetes scaffold for all team Odoo projects. Use this as the base for new Odoo instances.
> 
> **Template Features**:
> - Multi-environment Docker Compose (dev, ci, prod, test)
> - Bedrock-based Python venv structure
> - Docky v2 convention compliance
> - GitLab CI/CD integration
> - Kubernetes-ready configuration
> - PostgreSQL, Redis, and service containers
> - Backup/restore scripts
> 
> **Usage**:
> ```bash
> # Create new project from template
> cp -r app/second-brain/odoo-opensource-developper/real-odoo-shared-template my-odoo-project
> cd my-odoo-project
> # Customize docker-compose.yml, spec.yaml, etc.
> ```

### Docker & Docky Management Skill
> **Location**: `app/second-brain/odoo-opensource-developper/docker-docky-management/`
> 
> **Description**: Comprehensive skill for Docker and Docky management with AKRETION tools (DOCKY, PIPX, COPIER, AK). This skill provides detailed documentation, command references, and best practices for using Akretion's toolchain with Odoo development.
> 
> **Includes:**
> - Complete AKRETION tools documentation (Docky, Copier, AK, pipx)
> - Command reference for all tools
> - Multi-stage Dockerfile examples
> - docker-compose.yml templates
> - spec.yaml configuration examples
> - Workflow examples for common tasks
> - Troubleshooting guide
> - Best practices for Odoo containerization
> 
> **Supporting Files Directory**: `docker-docky-management/docker-docky-supporting-files/`
> 
> **Quick Access**:
> ```bash
> # Navigate to the skill directory
> cd app/second-brain/odoo-opensource-developper/docker-docky-management
> 
> # Read the SKILL.md for complete documentation
> # Supporting files are in docker-docky-supporting-files/
> ```

### 2. Kubernetes Deployment

**Architecture:**
- RKE2 HA cluster on OVH VPS (3 nodes)
- Namespaces: `fnfe-test`, `fnfe-preprod`, `fnfe-prod`, `erk18-test`
- GitOps: ArgoCD + Image Updater

**Deployment Files:**
- K8s manifests: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/odoo-fnfe/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/odoo-fnfe/), [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/odoo-erk18/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/odoo-erk18/)
- ArgoCD apps: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/argocd/apps/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/argocd/apps/)

**Quick Commands:**
```bash
# Apply test deployment
kubectl apply -f k8s/odoo-fnfe/ -n fnfe-test

# Check rollout status
kubectl rollout status deployment/odoo-14-fnfe -n fnfe-test --timeout=180s

# View logs
kubectl logs -f deployment/odoo-14-fnfe -n fnfe-test
```

### 3. CI/CD Pipeline

**GitLab CI Configuration:** [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/.gitlab-ci.yml`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/.gitlab-ci.yml)

**Pipeline Stages:**
1. **build**: Docker image construction
2. **update_db**: Database initialization and module updates
3. **publish**: Image tagging and registry push
4. **deploy**: Kubernetes deployment (via ArgoCD or direct kubectl)

**Key Variables (from .env.example):**
- `ODOO_URL`: Odoo instance URL
- `ODOO_API_KEY`: Odoo API key for external integrations
- `CI_REGISTRY_USER/PASSWORD`: Container registry credentials
- `GITLAB_PUSH_TOKEN`: Git push token for CI write-backs

### 4. Security & Access Management

**IAM Strategy:**
- Central OAuth provider: GitLab (gitlab.akretion.com)
- Service accounts: Separate tokens (never use human user tokens)
- Break-glass accounts: Local admin users for emergency access
- Secret storage: Passbolt CE + K8s secrets

**RBAC Structure:**
| GitLab Group | Rancher Role | Grafana Role | ArgoCD Role |
|--------------|--------------|--------------|-------------|
| `akretion/infra-admins` | Cluster Owner | Admin | admin |
| `akretion/developers` | Project Member | Editor | readonly |
| `akretion/viewers` | Project Viewer | Viewer | readonly |

**Passbolt Setup:**
- URL: https://passbolt.infra.legalides.eu
- Chart: passbolt/passbolt-helm v2.1.0
- See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/passbolt/passbolt-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/passbolt/passbolt-readme.md)

### 5. Factur-X & Electronic Invoicing

**Stack:**
- **Factur-X validator**: `factur-x-validator_UBL-CDAR-CTC` (submodule)
- **Odoo modules**: `odoo-fnfe` (vendored via git subtree)
- **Custom modules**: `report_py3o_fusion_server_fix` (local-src/)
- **Schemas**: UBL 2.1, CDC16B, CTC

**Key Modules:**
- `base_facturx`
- `facturx_validator`
- `account_invoice_facturx`
- `account_invoice_import_facturx`
- `account_invoice_facturx_py3o`
- `l10n_fr_account_invoice_facturx`
- `l10n_fr_account_invoice_import_facturx`

**Validation Flow:**
1. PDF invoice generation (py3o)
2. Factur-X XML embedding
3. verapdf REST validation (XSD + Schematron)
4. Chorus Pro compliance checks (when applicable)

### 6. py3o PDF Reporting

**Components:**
- **py3o.template**: ODT template rendering (Python 2.7 legacy)
- **py3o-fnfe container**: LibreOffice PDF conversion sidecar
- **Fusion server**: Remote PDF rendering service
- **verapdf**: PDF/A validation

**Known Issues & Fixes:**
- Python 3 compatibility patches (9 patches applied)
- LibreOffice filter registration
- GPG/JWT dependencies
- Company logo handling
- JSON serialization for Odoo records

**See:** py3o sections in [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) lines 345-903

### 7. Odoo Migration & OpenUpgrade

| Category | File | Description |
|----------|------|-------------|
| **Migration Guide (14.0→18.0)** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/odoo-migration/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/odoo-migration/README.md) | Complete step-by-step migration from Odoo 14.0 to 18.0 using OpenUpgrade |
| **Runboat CI System** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/runboat/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/runboat/README.md) | Kubernetes-based Odoo runbot alternative for automated testing |
| **OpenUpgrade Source** | [https://github.com/OCA/OpenUpgrade/tree/14.0](https://github.com/OCA/OpenUpgrade/tree/14.0) | Official OCA OpenUpgrade repository |
| **OpenUpgrade Documentation** | [https://oca.github.io/OpenUpgrade/](https://oca.github.io/OpenUpgrade/) | Complete OpenUpgrade documentation |
| **Migration Entrypoint** | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/start-entrypoint.d/004_open_upgrade`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-fnfe-front/start-entrypoint.d/004_open_upgrade) | Production migration trigger script |

---

## Development Workflows

### Adding a New Developer

**Reference:** [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md) (from erk-infra project)

**Steps:**
1. Add user to appropriate GitLab group
2. GitLab OAuth automatically provisions access to:
   - Rancher
   - Grafana
   - ArgoCD
3. User can authenticate via GitLab OAuth
4. Assign Kubernetes RBAC via GitLab group membership

**Command:**
```bash
# Verify user has access
kubectl get clusterrolebindings | grep <username>
```

### Deploying Code Changes

**For Odoo 18 ERK:**
```bash
# 1. Make changes in odoo18-erk/
# 2. Commit and push
# 3. CI automatically:
#    - builds image
#    - updates kustomize overlay
#    - ArgoCD auto-syncs to cluster

# Manual verification
kubectl get pods -n erk18-test -w
```

**For Odoo 14 FNFE:**
```bash
# Similar flow, but check odoo-k8s-readme.md for specific commands
```

### Database Management

**Initialization:**
```bash
# For Odoo 18
cd odoo18-erk
kubectl apply -f k8s/odoo-erk18/base/postgres-18.yaml
# Database created automatically by init container

# For Odoo 14
cd docker-vps-prod-v14
# See provisioning/Cluster-Install_README.md
```

**Backup:**
```bash
# Using kubectl and pg_dump
kubectl exec -n fnfe-test postgres-14-0 -- pg_dump -U odoo fnfe14 > fnfe14_backup.sql
```

**Restore:**
```bash
# Via kubectl and psql
cat fnfe14_backup.sql | kubectl exec -i -n fnfe-test postgres-14-0 -- psql -U odoo fnfe14
```

### Troubleshooting

**Common Issues:**

| Symptom | Likely Cause | Documentation |
|---------|--------------|----------------|
| Pod CrashLoopBackOff | Missing config, init container failure | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) §318-330 |
| py3o rendering errors | Python 3 compatibility | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) §345-624 |
| verapdf validation fails | XML format changed | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) §303-316 |
| GitLab CI deploy fails | KAS tunnel broken | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md) |
| OAuth login fails | GitLab nginx not configured | [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md) §44-88 |

**Debug Commands:**
```bash
# View pod logs
kubectl logs -f <pod-name> -n <namespace>

# Exec into running pod
kubectl exec -it <pod-name> -n <namespace> -- bash

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check ArgoCD sync status
argocd app get erk18-test
argocd app logs erk18-test
```

---

## Project-Specific Information

### FNFE-MPE Instance (Odoo 14)

- **Namespace**: fnfe-test, fnfe-preprod, fnfe-prod
- **Domain**: test.erp.akretion.cab (migrated from test.erp.legalides.eu)
- **Applications**: PostgreSQL, Odoo 14, Grafana, Passbolt, py3o, verapdf, kwkhtmltopdf
- **Factur-X**: Full validator stack with custom modules
- **Status**: Production-ready (2026-06-27)

**See:** [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md)

### ERK Instance (Odoo 18)

- **Namespace**: erk18-test (future: erk18-preprod, erk18-prod)
- **Domain**: erk.flows.cab
- **Base Image**: ghcr.io/akretion/odoo-docker:18.0-light-latest
- **Registry**: registry.gitlab.akretion.com/akretion/fnfe/odoo18-erk
- **Image Tag**: v18-erk-test
- **Database**: postgres:16
- **Status**: Test deployment active

**See:** [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md)

### Fnfe18-Front Instance (Odoo 18)

- **Namespace**: fnfe18-front
- **Domain**: fnfe.flows.cab
- **Features**: Factur-X validator, odoo-fnfe modules, OCA/rest-framework FastAPI
- **Deployment Date**: 2026-07-10
- **K8s Manifests**: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/odoo-fnfe18-front/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/odoo-fnfe18-front/)
- **CI Jobs**: `/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/.gitlab-ci.yml` *-fnfe-front jobs

**See:** [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md) §9-15

---

## Security Best Practices

### Never Store in Git
- Passwords, tokens, API keys
- Private SSH keys
- Database connection strings
- Certificates (unless public)
- Any sensitive configuration

### Use Instead
- **Passbolt**: For team-shared secrets
- **K8s Secrets**: For cluster-level credentials
- **GitLab CI Variables**: For CI/CD pipeline secrets (masked + protected)
- **Vault/External Secret Managers**: For production-grade secret management

### .gitignore Patterns
```gitignore
# Secrets
*.secret
*.secret.yaml
*secret*.yaml
*password*
*token*
*key.pem

# Local development
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/

# Build artifacts
*.pyc
__pycache__/
*.egg-info/
.dist/
.build/
```

### Break-Glass Accounts
Maintain local admin accounts for emergency access when OAuth/GitLab is unavailable:
- Rancher: `admin` (Passbolt: "Rancher admin")
- ArgoCD: `admin` (Passbolt: "ArgoCD admin")
- Grafana: `admin` (Passbolt: "Grafana admin")

**Never delete these accounts after enabling OAuth.**

---

## Technology Stack Summary

| Category | Technology | Version | Purpose |
|----------|------------|---------|---------|
| **Container Runtime** | RKE2 | v1.28+ | Kubernetes distribution |
| **Container Build** | Docker | 24.x | Image building |
| **CI/CD** | GitLab CI | 16.x | Pipeline orchestration |
| **GitOps** | ArgoCD | 2.9+ | Declarative deployment |
| **GitOps** | Image Updater | latest | Image tag automation |
| **Odoo Base** | odoo | 14.0, 18.0 | ERP core |
| **Odoo Template** | Bedrock | 14.0-py310, 18.0-light | Python venv scaffold |
| **Odoo Template** | Docky | v2 | Docker conventions |
| **Database** | PostgreSQL | 14, 16 | Data persistence |
| **PDF Engine** | py3o | 0.10.0 | ODT→PDF rendering |
| **PDF Validation** | verapdf | 1.31+ | PDF/A compliance |
| **PDF Conversion** | kwkhtmltopdf | latest | HTML→PDF |
| **Secret Management** | Passbolt | CE | Team password vault |
| **Monitoring** | Grafana | 10.x | Dashboards & alerts |
| **Monitoring** | Prometheus | 2.x | Metrics collection |
| **Logging** | Loki | latest | Log aggregation |
| **Ingress** | Nginx | latest | HTTP routing & TLS |
| **TLS** | cert-manager | 1.x | Let's Encrypt automation |
| **IAM** | GitLab OAuth | 16.x | Central authentication |

---

## Quick Navigation Commands

```bash
# Show all README files in this repo
find . -name "*README.md" -o -name "*readme.md" | sort

# Search for specific topics
grep -r "Factur-X" --include="*.md" .
grep -r "py3o" --include="*.md" .
grep -r "k8s" --include="*.md" .

# List all K8s manifests
find k8s/ -name "*.yaml" -o -name "*.yml" | sort

# List all Dockerfiles
find . -name "Dockerfile" | sort

# List all spec.yaml files (git-aggregator)
find . -name "spec.yaml" | sort

# List Odoo templates
find . -name "*template*" -type d | sort
```

---

## Triggers for This Skill

This skill is automatically invoked when you ask about:
- Odoo development, customization, or debugging
- Kubernetes/RKE2 cluster management
- Docker containerization
- GitLab CI/CD pipelines
- ArgoCD GitOps deployments
- Factur-X electronic invoicing
- py3o PDF reporting
- Passbolt secret management
- Infrastructure as Code (OpenTofu/Terraform)
- Multi-repository management (git-aggregator/ak)
- Database administration for Odoo
- Troubleshooting containerized Odoo instances

---

## Usage Examples

**"How do I deploy Odoo 18 to Kubernetes?"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo18-AK-template_README.md)

**"I need to add a new developer to the cluster"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md) (in erk-infra project)

**"How do I fix py3o rendering errors?"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) §345-624

**"What's the Factur-X validation flow?"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/odoo-k8s-readme.md) §250-307

**"How do I set up the GitLab Kubernetes agent?"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/gitlab-runner/gitlab-admin_README.md)

**"How do I deploy Passbolt on K8s?"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/passbolt/passbolt-readme.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/k8s/infra/passbolt/passbolt-readme.md)

**"What's the CI/CD pipeline structure?"**
→ See: [`/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/.gitlab-ci.yml`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14/.gitlab-ci.yml)

---


"**How do I migrate Odoo 14.0 to 18.0?"**
→ See: [migration guide](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/odoo-migration/README.md)

"**How do I set up Runboat for OCA repositories?"**
→ See: [runboat guide](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/runboat/README.md)

"**How do I create migration scripts for my custom modules?"**
→ See: [script generation](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/odoo-migration/README.md#33--step-3-migration-script-generation)

---

## User Interaction Guide

**When chatting with users about Odoo migration, ALWAYS ask these primary questions:**

1. **"Which is your list of modules you need to migrate?"**
   - This helps identify coverage gaps in OpenUpgrade
   - Allows generation of custom migration scripts for missing modules
   - Estimates migration complexity and effort

2. **"How can I help you on the script generation?"**
   - Offer to create missing migration scripts
   - Provide templates for common migration patterns
   - Review and validate existing custom scripts

**Additional helpful questions for migration discussions:**
- "Do you have any custom modules?"
- "Are you using any third-party modules?"
- "What is your current Odoo version?"
- "What is your target Odoo version?"
- "What is your database size?"
- "Do you have a test environment for migration?"
- "What is your target deployment date?"
- "Do you need assistance with rollback planning?"

---
## Important Notes

1. **All sensitive information** (passwords, IPs, tokens, keys) is stored in:
   - Passbolt vault (https://passbolt.infra.legalides.eu)
   - K8s secrets (managed via kubectl)
   - GitLab CI protected variables
   - The referenced README files (which may reference the above)

2. **This SKILL.md file contains NO sensitive data** - it only points to documentation files.

3. **Always follow the principle of least privilege** when granting access.

4. **Never commit secrets to version control** - use .gitignore and external secret managers.

5. **For production deployments**, always test in staging first (fnfe-test, erk18-test).

6. **ArgoCD is the source of truth** for K8s deployments - manual kubectl apply should be rare.

---

## Document Version

- **Created**: 2026-07-10
- **Based on**: docker-vps-prod-v14 repository at `/home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/AK/FNFE/docker-vps-prod-v14`
- **Maintainer**: Odoo Open-Source Developer Team
- **Related Skills**: infra-k8s-manager (in erk-infra project)

---

*For the most up-to-date information, always refer to the source README files in the repository.*
