---
name: infra-k8s-manager
description: Manage OVH-hosted RKE2 infra: Kubernetes, ArgoCD, Odoo.
version: 1.0.0
---

# infra-k8s-manager

## Overview

This skill provides comprehensive guidance for managing your OVH-hosted RKE2 infrastructure. All sensitive information (IPs, tokens, SSH keys, passwords, certificates) is stored in the referenced README files, which are already part of your `2.erk-infra` project.

> **Important**: This project uses **GitLab** for version control, not GitHub. Prioritize `glab` commands which are already installed and configured on this system for GitLab operations.

---

## Table of Contents

1. [Core Infrastructure Documentation](#core-infrastructure-documentation)
2. [Quick Navigation](#quick-navigation)
3. [Security Notes](#security-notes)
4. [IT Architecture & Visualization](#it-architecture--visualization)
5. [Core Tools](#core-tools)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Integration Workflow](#integration-workflow)
8. [GitLab Repository](#gitlab-repository)
9. [Triggers](#triggers)
10. [Usage Examples](#usage-examples)

---

## Core Infrastructure Documentation

### Cluster Management & Provisioning

| Topic | Documentation File | Description |
|-------|---------------------|-------------|
| **Cluster Provisioning** | [`/provisioning/Cluster-Install_README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/provisioning/Cluster-Install_README.md) | Complete guide for VPS provisioning, RKE2 setup, and application deployment |
| **DNS Management** | [`/provisioning/dns-mail/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/provisioning/dns-mail/) | DNS records and mail configuration for Infomaniak |
| **IAM & Access Control** | [`/platform/iam/README.md`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md) | Developer onboarding, Kubernetes RBAC, ArgoCD access |

---

## Quick Navigation

### Cluster Operations
```bash
# View cluster provisioning guide
cat /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/provisioning/Cluster-Install_README.md

# Access management and developer onboarding
cat /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md
```

---

## Security Notes

> **Important**: All sensitive information (IP addresses, tokens, SSH keys, passwords, certificates) is stored in the referenced README files in your `2.erk-infra` project. This skill document only points to those files and contains no sensitive data itself.

### Security Practices

- **Never** commit passwords, tokens, or private keys to version control
- Use **Passbolt** for secret storage (as documented in your README files)
- Follow the **least-privilege principle**
- Keep sensitive files in `.gitignore`

---

## IT Architecture & Visualization

### Overview

This section provides guidance for illustrating workload and relationships between your Kubernetes infrastructure, Odoo instances, GitLab repositories, and AI tools. It supports three levels of assistance for developers.

### Three Levels of Support

#### Level 1: Internal Tools Management
Help developers navigate and manage internal infrastructure:

- Kubernetes cluster access, monitoring, and troubleshooting
- Odoo instance management and deployment
- GitLab project navigation and CI/CD pipeline management
- AI tool integration and usage

#### Level 2: Odoo Module & Migration Design
Assist developers in designing and implementing:

- New Odoo modules with proper architecture patterns
- Database migrations and schema changes
- Integration patterns with existing infrastructure
- Best practices for Odoo development

#### Level 3: Vulgarization & Schematization
Provide visualization and documentation capabilities:

- Architecture diagrams for stakeholders
- Workload distribution illustration
- Technical documentation generation
- Presentation creation for non-technical audiences

---

## Core Tools

> **Current Status (2026-08-05)**: PlantUML and Marp are already deployed — in the `ai-tools` namespace (not `doc-tools` as the deployment options below describe), as `plantuml-service`/`marp-server`. See [`app/ai-tools/plantuml-cli/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/plantuml-cli/) and [`app/ai-tools/marp-cli/`](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/marp-cli/). Hermes itself doesn't call these as MCP servers (neither speaks the MCP protocol) — it uses direct `curl`/`npx` calls, documented as native Hermes skills: `plantuml`, `marp`, and `infra-architecture-diagram` (which routes between them and the bundled `architecture-diagram` skill). The Helm/raw-manifest instructions below are the original design reference, useful if redeploying to a different namespace/cluster, not a to-do.

### Kubernetes MCP Server

**Status**: Available using service account credentials

**Configuration**:
```json
{
  "kubernetes": {
    "command": "kubectl",
    "args": [
      "--server=https://10.43.0.1:443",
      "--certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
      "--token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)",
      "--namespace=ai-tools"
    ],
    "timeout": 30000,
    "retries": 3
  }
}
```

**Available Tools**:
- `kubernetes/get_pods` - List pods in namespace
- `kubernetes/get_logs` - Get pod logs
- `kubernetes/describe` - Describe resources
- `kubernetes/apply` - Apply manifests
- `kubernetes/delete` - Delete resources

### PlantUML

**Purpose**: Generate architecture diagrams from text-based descriptions

**Deployment Target**: Already deployed as `plantuml-service` in `ai-tools` (see status note above)

**Usage Options**:
- VSCode extension (recommended for development)
- GitLab plugin (research in progress for integration)
- Neovim plugin (research in progress)
- Standalone server deployment (done — see status note above)

**Resources**: [PlantUML Documentation](https://plantuml.com/)

### Marp CLI

**Purpose**: Create presentations from Markdown files

**Status**: Already available to Hermes via its bundled Node runtime (`npx @marp-team/marp-cli`) — no separate install needed inside the Hermes pod. `marp-server` (HTTP wrapper) is also deployed in `ai-tools` for other consumers.

**Installation** (for local/other-environment use):
```bash
npm install -g @marp-team/marp-cli
```

**Usage Examples**:
```bash
# Generate PDF presentation
marp slides.md --pdf output.pdf

# Generate PowerPoint presentation
marp slides.md --pptx output.pptx

# Serve slides locally for preview
marp --server slides.md
```

**Resources**: [Marp GitHub](https://github.com/marp-team/marp-cli)

---

## Kubernetes Deployment

### PlantUML Server Deployment

Deploy PlantUML server on your RKE2 cluster:

### Option 1: Helm (Recommended)
```bash
# Create namespace for documentation tools
kubectl create namespace doc-tools

# Add Helm repository and install
helm repo add plantuml https://johanhaleby.github.io/plantuml-server
helm install plantuml plantuml/plantuml-server -n doc-tools \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=plantuml.your-domain.com
```

### Option 2: Raw Manifest
```bash
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: plantuml-server
  namespace: doc-tools
spec:
  replicas: 1
  selector:
    matchLabels:
      app: plantuml-server
  template:
    metadata:
      labels:
        app: plantuml-server
    spec:
      containers:
      - name: plantuml
        image: plantuml/plantuml-server:jetty
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1"
---
apiVersion: v1
kind: Service
metadata:
  name: plantuml-service
  namespace: doc-tools
spec:
  selector:
    app: plantuml-server
  ports:
  - port: 80
    targetPort: 8080
EOF
```

### Marp CLI Server Deployment

Deploy Marp CLI as a server on your RKE2 cluster for team presentation generation:

**Official Docker Image**: `marpteam/marp-cli`

**Resources**: [Docker Hub - marpteam/marp-cli](https://hub.docker.com/r/marpteam/marp-cli/)

#### Option 1: Raw Manifest (Recommended)
```bash
# Create PVC for slide storage (optional but recommended)
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: marp-slides-pvc
  namespace: doc-tools
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF

# Deploy Marp CLI server
kubectl apply -f - << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: marp-cli
  namespace: doc-tools
spec:
  replicas: 1
  selector:
    matchLabels:
      app: marp-cli
  template:
    metadata:
      labels:
        app: marp-cli
    spec:
      containers:
      - name: marp-cli
        image: marpteam/marp-cli:latest
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 37717
          name: livereload
        volumeMounts:
        - name: slides
          mountPath: /home/marp/app
        env:
        - name: LANG
          value: "en_US.UTF-8"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: slides
        persistentVolumeClaim:
          claimName: marp-slides-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: marp-cli-service
  namespace: doc-tools
spec:
  selector:
    app: marp-cli
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  - name: livereload
    port: 37717
    targetPort: 37717
EOF

# Create Ingress (optional)
cat << 'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: marp-cli-ingress
  namespace: doc-tools
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: marp.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: marp-cli-service
            port:
              number: 8080
EOF
```

#### Option 2: Server Mode for Local Development
```bash
# Run marp-cli in server mode locally
marp --server slides.md
# Access at http://localhost:8080

# Or with Docker
docker run --rm --init -v $PWD:/home/marp/app -e LANG=$LANG -p 8080:8080 -p 37717:37717 marpteam/marp-cli -s .
```

#### Usage Commands for Conversion
```bash
# Convert to HTML
kubectl exec -n doc-tools deploy/marp-cli -- marp /home/marp/app/slides.md -o output.html

# Convert to PDF
kubectl exec -n doc-tools deploy/marp-cli -- marp /home/marp/app/slides.md --pdf -o output.pdf

# Convert to PowerPoint
kubectl exec -n doc-tools deploy/marp-cli -- marp /home/marp/app/slides.md --pptx -o output.pptx
```

---

## Integration Workflow

1. **Design Phase**: Use PlantUML to create architecture diagrams for new Odoo modules
2. **Development Phase**: Store diagrams in GitLab WIKI or repository
3. **Documentation Phase**: Use Marp to create presentations explaining the architecture
4. **Review Phase**: Share diagrams and presentations with team via GitLab

PlantUML/Marp are already deployed on K8S (`ai-tools` namespace) — see [Core Tools](#core-tools) above and the `infra-architecture-diagram` Hermes skill for the full tool-selection guide.

---

## GitLab Repository

**Primary Repository**: [https://gitlab.akretion.com/akretion/fnfe](https://gitlab.akretion.com/akretion/fnfe)

### GitLab Configuration

**Akretion GitLab Instance**: `https://gitlab.akretion.com/api/v4`
**Authentication Token**: Available in `GITLAB_AK_TOKEN` environment variable

### Available Repositories

You have access to the following repositories:
- **fnfe**: [https://gitlab.akretion.com/akretion/fnfe](https://gitlab.akretion.com/akretion/fnfe)
- **fnfempe**: [https://gitlab.akretion.com/akretion/fnfempe](https://gitlab.akretion.com/akretion/fnfempe)

### GitLab API Usage

**Basic API Command Template**:
```bash
# Get user information
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/user"

# List accessible projects
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true&per_page=100"

# Get repository structure
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe/repository/tree?recursive=false"
```

### Key Features to Utilize

- **WIKI pages**: Central location for technical documentation and architecture decisions
- **Project management**: Boards for tracking architecture tasks and module development
- **CI/CD pipelines**: Automation for Odoo module testing and deployment
- **Merge requests**: Code review process for new modules and migrations

### Repository Cloning

**Clone fnfe repository**:
```bash
# HTTPS
git clone https://gitlab.akretion.com/akretion/fnfe.git

# SSH
git clone ssh://git@gitlab.akretion.com:10022/akretion/fnfe.git
```

**Clone fnfempe repository**:
```bash
# HTTPS
git clone https://gitlab.akretion.com/akretion/fnfempe.git

# SSH
git clone ssh://git@gitlab.akretion.com:10022/akretion/fnfempe.git
```

---

## Quick Start Commands

### Install Marp CLI
```bash
npm install -g @marp-team/marp-cli
```

### Create a Simple Architecture Diagram
```bash
cat > architecture.puml << 'EOF'
@startuml
skinparam monochrome true

cloud "OVH Cloud" {
  node "RKE2 Cluster" {
    [Kubernetes]
    [ArgoCD]
    [Odoo Pods]
  }
}

[GitLab] --> [Kubernetes] : CI/CD
[AI Tools] --> [Odoo Pods] : Integration

@enduml
EOF
```

> **Note**: See PlantUML deployment section above for diagram generation

---

## GitLab Plugin Research

### Action Items

- Research PlantUML plugin for GitLab for direct diagram rendering in merge requests
- Research Neovim plugin for PlantUML editing and preview
- Evaluate GitLab Markdown rendering for PlantUML diagrams

---

## Triggers

This skill is automatically invoked when you ask about:

### Infrastructure Management
- Kubernetes cluster management
- RKE2 operations
- DNS configuration (Infomaniak)
- Developer access and onboarding
- ArgoCD setup and permissions
- Infrastructure as Code (OpenTofu/Terraform)
- RBAC configuration
- Cluster troubleshooting
- Kubernetes API access and kubectl usage

### Architecture & Visualization
- IT architecture visualization
- Odoo module design and architecture
- PlantUML deployment or usage
- Marp CLI presentations
- GitLab architecture documentation
- Schematization of infrastructure relationships
- Workload distribution illustration

---

## Usage Examples

### Infrastructure Management

| Question | Solution |
|----------|----------|
| I need to add a new developer to my Kubernetes cluster | See [IAM README](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/platform/iam/README.md) |
| How do I provision a new RKE2 cluster on OVH? | See [Cluster Install README](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/provisioning/Cluster-Install_README.md) |
| DNS migration procedures | See [DNS/Mail directory](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/provisioning/dns-mail/) |
| How to troubleshoot kubeconfig issues? | See [Cluster Install README](file:///home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/provisioning/Cluster-Install_README.md) |
| How to use kubectl with the Kubernetes MCP server? | Use the configured MCP server with service account credentials (see [Kubernetes MCP Server](#kubernetes-mcp-server)) |

### Architecture & Visualization

| Question | Solution |
|----------|----------|
| How do I create an architecture diagram for my Odoo module? | See [PlantUML section](#plantuml) above |
| Deploy PlantUML server on our K8S cluster | See [PlantUML Server Deployment](#plantuml-server-deployment) above |
| Deploy Marp CLI on our K8S cluster | See [Marp CLI Server Deployment](#marp-cli-server-deployment) above |
| Create a presentation for stakeholders using Marp | See [Marp CLI section](#marp-cli) above |
| Where should I document the new module architecture? | Use GitLab WIKI at [https://gitlab.akretion.com/akretion/fnfe/-/wikis](https://gitlab.akretion.com/akretion/fnfe/-/wikis) |
| What's the workflow for designing a new Odoo module? | See [Integration Workflow](#integration-workflow) above |

---

*For specific tasks, refer to the README files for infrastructure management, or the IT Architecture & Visualization section for diagram and documentation needs.*