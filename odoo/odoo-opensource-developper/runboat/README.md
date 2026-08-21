# Runboat Setup for OCA/vertical-association

**Runboat** is a Kubernetes-native Odoo runbot alternative designed to replace the OCA runbot. It manages Odoo instances with pre-installed addons from GitHub repositories (branches, PRs) as **builds** in Kubernetes.

This guide provides a **complete setup** for running `OCA/vertical-association` through Runboat in your existing **RKE2 Kubernetes cluster** (`flows.cab` infrastructure).

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR EXISTING INFRA                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    RKE2 Cluster (OVH)                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────────────┐  │  │
│  │  │  Postgres   │  │   Runboat   │  │   Odoo Builds     │  │  │
│  │  │  (existing) │  │  Controller  │  │   (dynamic)        │  │  │
│  │  └─────────────┘  └─────────────┘  └───────────────────┘  │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Namespace: runboat                      │  │  │
│  │  │  • Controller Deployment + Service                 │  │  │
│  │  │  • Build Deployments (auto-created/destroyed)       │  │  │
│  │  │  • Ingress: *.runboat.flows.cab                     │  │  │
│  │  │  • Persistent Volumes for DBs and filestores        │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                             │
│  GitHub Webhook ┬───────────────────────────────┬ Git Push/PR   │
│    (oca/vertical-association)                 │                │
└────────────────┴───────────────────────────────┴───────────────┘
```

---

## ✅ Prerequisites (Already in Your Infrastructure)

Your existing setup from `odoo-k8s-readme.md` and `odoo18-AK-template_README.md` provides:

| Requirement | Your Existing Setup | Status |
|-------------|---------------------|--------|
| Kubernetes Cluster | RKE2 on OVH VPS | ✅ Ready |
| PostgreSQL | `postgres-14` service | ✅ Ready (reusable) |
| Ingress Controller | Nginx with cert-manager | ✅ Ready |
| Wildcard DNS | `*.flows.cab` | ✅ Ready |
| Storage Class | Default (local-path or OVH) | ✅ Ready |
| GitLab CI | Existing pipeline | ✅ Ready |

---

## 📦 Step 1: Clone Runboat Repository

```bash
cd /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/runboat

git clone https://github.com/sbidoul/runboat.git
cd runboat
```

---

## 🛠️ Step 2: Configuration for OCA/vertical-association

### 2.1 Environment Configuration (`.env`)

Create `.env` file in the runboat directory:

```bash
# Runboat Controller Configuration
RUNBOAT_CONFIG_FILE=/app/runboat/config.yaml

# Kubernetes
KUBERNETES_NAMESPACE=runboat
KUBECONFIG=/app/kubeconfig  # Will be mounted from service account
RUNBOAT_BUILD_DEFAULT_KUBEFILES_PATH=/app/runboat/src/runboat/kubefiles

# PostgreSQL (use your existing from odoo-k8s-readme.md)
RUNBOAT_DB_HOST=postgres-14
RUNBOAT_DB_PORT=5432
RUNBOAT_DB_USER=odoo
RUNBOAT_DB_PASSWORD_FILE=/app/db-password  # Mounted from K8s secret
RUNBOAT_DB_NAME=runbot_db

# Build Domain
RUNBOAT_BUILD_DOMAIN=runboat.flows.cab

# GitHub
RUNBOAT_GITHUB_WEBHOOK_SECRET_FILE=/app/webhook-secret  # 32-char random string

# Build Limits
RUNBOAT_MAX_BUILD_AGE=30  # Days to keep old builds
RUNBOAT_MAX_STARTED_BUILD_AGE=7  # Days to keep started builds
RUNBOAT_MAX_BUILD_COUNT=100
RUNBOAT_MAX_STARTED_BUILD_COUNT=20
RUNBOAT_MAX_CONCURRENT_INIT_JOBS=4

# Repositories Configuration
RUNBOAT_REPOS='[{"repo": "^OCA/vertical-association$", "branch": "^(14\.0|16\.0|18\.0)$", "builds": [{"image": "ghcr.io/oca/oca-ci/py3.8-odoo16.0:latest"}]}]'
```

### 2.2 Kubernetes Manifests for OCA/vertical-association

Create `k8s/runboat-vertical-association.yaml`:

```yaml
---
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: runboat
  labels:
    name: runboat

---
# Service Account with permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: runboat
  namespace: runboat

---
# Role for Runboat
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: runboat
  name: runboat
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services", "configmaps", "secrets", "persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

---
# Role Binding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: runboat
  namespace: runboat
subjects:
- kind: ServiceAccount
  name: runboat
  namespace: runboat
roleRef:
  kind: Role
  name: runboat
  apiGroup: rbac.authorization.k8s.io

---
# ConfigMap for Runboat configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: runboat-config
  namespace: runboat
data:
  config.yaml: |
    repos:
      - repo: "^OCA/vertical-association$"
        branch: "^(14\.0|16\.0|18\.0)$"
        builds:
          - image: "ghcr.io/oca/oca-ci/py3.8-odoo16.0:latest"
    
    build_domain: "runboat.flows.cab"
    max_build_age: 30
    max_started_build_age: 7
    max_build_count: 100
    max_started_build_count: 20
    max_concurrent_init_jobs: 4

---
# Secrets (create separately - see below)
# kubectl create secret generic runboat-secrets -n runboat \
#   --from-literal=db-password=$(pass show odoo/runbot-db) \
#   --from-literal=webhook-secret=$(openssl rand -hex 32)

---
# Runboat Controller Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: runboat
  namespace: runboat
  labels:
    app: runboat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: runboat
  template:
    metadata:
      labels:
        app: runboat
    spec:
      serviceAccountName: runboat
      containers:
      - name: runboat
        image: ghcr.io/sbidoul/runboat:latest
        imagePullPolicy: Always
        env:
        - name: RUNBOAT_CONFIG_FILE
          value: /app/config/config.yaml
        - name: RUNBOAT_DB_HOST
          value: postgres-14
        - name: RUNBOAT_DB_PORT
          value: "5432"
        - name: RUNBOAT_DB_USER
          value: odoo
        - name: RUNBOAT_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: runboat-secrets
              key: db-password
        - name: RUNBOAT_GITHUB_WEBHOOK_SECRET
          valueFrom:
            secretKeyRef:
              name: runboat-secrets
              key: webhook-secret
        - name: KUBERNETES_NAMESPACE
          value: runboat
        - name: RUNBOAT_BUILD_DOMAIN
          value: runboat.flows.cab
        ports:
        - containerPort: 8000
          name: http
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: runboat-config

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: runboat
  namespace: runboat
spec:
  selector:
    app: runboat
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000

---
# Ingress with TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: runboat
  namespace: runboat
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  tls:
  - hosts:
    - runboat.flows.cab
    secretName: runboat-tls
  rules:
  - host: runboat.flows.cab
    http:
      paths:
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: runboat
            port:
              number: 80
```

---

## ⚙️ Step 3: Deploy Runboat

### 3.1 Create Secrets

```bash
# Generate webhook secret
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Get DB password from Passbolt (or create new one)
DB_PASSWORD=$(pass show odoo/runbot-db) || DB_PASSWORD=$(openssl rand -hex 24)

# Create secrets in Kubernetes
kubectl create secret generic runboat-secrets -n runboat \
  --from-literal=db-password="$DB_PASSWORD" \
  --from-literal=webhook-secret="$WEBHOOK_SECRET"
```

### 3.2 Apply Kubernetes Manifests

```bash
# Apply all Runboat resources
kubectl apply -f k8s/runboat-vertical-association.yaml

# Verify deployment
kubectl get pods -n runboat -w

# Wait for Runboat to be ready
kubectl wait --for=condition=available deployment/runboat -n runboat --timeout=300s
```

### 3.3 Configure GitHub Webhook

1. Go to: https://github.com/OCA/vertical-association/settings/hooks
2. Click **Add webhook**
3. Configuration:
   - **Payload URL**: `https://runboat.flows.cab/runboat/hook/github`
   - **Content type**: `application/json`
   - **Secret**: `<your-webhook-secret>` (from K8s secret)
   - **Which events**: `Push`, `Pull request`, `Issue comment`
   - **Active**: ✅ Checked

4. Click **Add webhook**

---

## 🎯 Step 4: Configure OCA/vertical-association Repository

### 4.1 Repository Configuration

The Runboat configuration in `k8s/runboat-vertical-association.yaml` already includes:

```yaml
repos:
  - repo: "^OCA/vertical-association$"
    branch: "^(14\.0|16\.0|18\.0)$"
    builds:
      - image: "ghcr.io/oca/oca-ci/py3.8-odoo16.0:latest"
```

This will:
- Monitor the `OCA/vertical-association` repository
- Trigger builds for branches matching `14.0`, `16.0`, or `18.0`
- Use the OCA CI Docker image with Odoo 16.0

### 4.2 Custom Kubefiles (Optional)

If you need custom Odoo configuration, create `k8s/kubefiles-vertical-association/` with modified kubefiles:

```yaml
# k8s/kubefiles-vertical-association/kustomization.yaml
resources:
- ../runboat/src/runboat/kubefiles

configMapGenerator:
- name: odoo-config
  behavior: merge
  literals:
    - "[options]\nadmin_passwd = $(RUNBOAT_ADMIN_PASSWORD)"

patches:
- path: patches/add-vertical-association-deps.yaml
```

Then update the repo configuration:

```yaml
repos:
  - repo: "^OCA/vertical-association$"
    branch: "^(14\.0|16\.0|18\.0)$"
    builds:
      - image: "ghcr.io/oca/oca-ci/py3.8-odoo16.0:latest"
        kubefiles_path: "/app/kubefiles-vertical-association"
```

---

## 🔍 Step 5: Verify and Test

### 5.1 Check Runboat API

```bash
# Get the Runboat URL
RUNBOAT_URL=https://runboat.flows.cab

# List builds (initially empty)
curl -s $RUNBOAT_URL/runboat/api/builds | jq

# Check health
curl -s $RUNBOAT_URL/runboat/api/health
```

### 5.2 Trigger Manual Build

```bash
# Trigger a build for a specific branch
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"repo": "OCA/vertical-association", "branch": "16.0", "target_branch": "16.0"}' \
  $RUNBOAT_URL/runboat/api/builds
```

### 5.3 Access Build

Once a build is deployed and started:
- URL: `https://{branch}-{repo}-{commit}.runboat.flows.cab`
- Example: `https://16-0-oca-vertical-association-abc1234.runboat.flows.cab`

---

## 📊 Step 6: Integrate with GitLab CI (Optional)

Add to your `.gitlab-ci.yml` (similar to your existing FNFE setup):

```yaml
runboat-trigger:
  stage: test
  image: curlimages/curl:latest
  rules:
    - if: $CI_PIPELINE_SOURCE == "push" || $CI_PIPELINE_SOURCE == "merge_request_event"
      when: always
  script:
    - |
      BUILD_DATA=$(jq -n \
        --arg repo "$CI_PROJECT_NAME" \
        --arg branch "$CI_COMMIT_REF_NAME" \
        --arg sha "$CI_COMMIT_SHA" \
        --arg target "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" \
        '{
          "repo": $repo,
          "branch": $branch,
          "target_branch": ($target // $branch),
          "commit": $sha
        }')
      
      curl -X POST \
        -H "Content-Type: application/json" \
        -d "$BUILD_DATA" \
        https://runboat.flows.cab/runboat/api/builds
  environment:
    name: runboat
    url: https://runboat.flows.cab
```

---

## 🔧 Customization for Your Infrastructure

### 6.1 Match Your Odoo Version

Update the image in the repo configuration to match your Odoo version:

```yaml
builds:
  # For Odoo 14
  - image: "ghcr.io/oca/oca-ci/py3.8-odoo14.0:latest"
  
  # For Odoo 16
  - image: "ghcr.io/oca/oca-ci/py3.8-odoo16.0:latest"
  
  # For Odoo 18
  - image: "ghcr.io/oca/oca-ci/py3.11-odoo18.0:latest"
```

### 6.2 Database Configuration

Runboat needs a database to store build metadata. Use your existing PostgreSQL:

```yaml
# In your ConfigMap
data:
  config.yaml: |
    db_uri: postgresql://odoo:$(RUNBOAT_DB_PASSWORD)@postgres-14:5432/runbot_db
```

Initialize the database:

```bash
# Connect to your PostgreSQL
kubectl exec -it deployment/postgres-14 -n fnfe-test -- psql -U odoo

# Create database and user
CREATE DATABASE runbot_db;
CREATE USER runbot WITH PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE runbot_db TO runbot;
```

### 6.3 Storage Configuration

Runboat needs storage for:
- PostgreSQL databases (per build)
- Filestores (per build)
- Virtual environments

Your existing Storage Class should work. Verify:

```bash
kubectl get storageclass
```

---

## 📈 Monitoring and Maintenance

### 7.1 Check Build Status

```bash
# List all builds
curl -s https://runboat.flows.cab/runboat/api/builds | jq '.[] | {id, repo, branch, status}'

# Get build details
curl -s https://runboat.flows.cab/runboat/api/builds/{build_id} | jq

# Get build logs
curl -s https://runboat.flows.cab/runboat/api/builds/{build_id}/logs | jq
```

### 7.2 Cleanup Old Builds

Runboat automatically cleans up old builds based on your configuration. To manually clean:

```bash
# Stop all started builds
kubectl get deployments -n runboat -l runboat/build -o name | xargs -I {} kubectl scale {} --replicas=0 -n runboat

# Delete old builds
kubectl delete deployments -n runboat -l runboat/build --field-selector=metadata.creationTimestamp<2026-06-21T00:00:00Z
```

### 7.3 Upgrade Runboat

```bash
# Update the image in your deployment
kubectl set image deployment/runboat runboat=ghcr.io/sbidoul/runboat:latest -n runboat

# Restart
kubectl rollout restart deployment/runboat -n runboat
```

---

## 🚨 Troubleshooting

### Issue: Builds Not Starting

```bash
# Check Runboat logs
kubectl logs -f deployment/runboat -n runboat

# Check for events
kubectl get events -n runboat --sort-by='.metadata.creationTimestamp'
```

**Common causes:**
- Missing RBAC permissions
- PostgreSQL connection issues
- Webhook not configured correctly
- GitHub rate limits (if not using token)

### Issue: Builds Failing During Initialization

```bash
# Get initialization job logs
JOB=$(kubectl get jobs -n runboat -l runboat/build={build_id},runboat/job-kind=initialize -o name)
kubectl logs -f $JOB -n runboat
```

**Common causes:**
- Missing dependencies in the Docker image
- Database connection issues
- Odoo installation errors

### Issue: Ingress Not Working

```bash
# Check ingress
kubectl get ingress -n runboat
kubectl describe ingress runboat -n runboat

# Check cert-manager
kubectl get certificaterequest -n runboat
kubectl describe certificaterequest -n runboat
```

**Solution:** Ensure your DNS wildcard `*.runboat.flows.cab` points to your cluster's ingress IP.

---

## 📚 References

- **Runboat GitHub**: https://github.com/sbidoul/runboat
- **Runboat Documentation**: https://github.com/sbidoul/runboat/wiki
- **OCA/vertical-association**: https://github.com/OCA/vertical-association
- **OCA CI Images**: https://github.com/OCA/oca-ci/pkgs/container/oca-ci

---

## 🎯 Quick Start Commands

```bash
# 1. Clone and enter
cd /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/runboat
git clone https://github.com/sbidoul/runboat.git

# 2. Create K8s resources
kubectl create ns runboat
kubectl create secret generic runboat-secrets -n runboat \
  --from-literal=db-password=$(pass show odoo/runbot-db) \
  --from-literal=webhook-secret=$(openssl rand -hex 32)

# 3. Apply manifests
kubectl apply -f k8s/runboat-vertical-association.yaml

# 4. Access Runboat
open https://runboat.flows.cab
```

---

*This guide integrates Runboat with your existing infrastructure from `odoo-k8s-readme.md` and `odoo18-AK-template_README.md`.*
