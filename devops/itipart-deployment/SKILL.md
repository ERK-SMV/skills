---
name: itipart-deployment
description: Manage ITIPART customer deployment on OVH-hosted RKE2.
version: 1.0.0
parent_skill: infra-k8s-manager
---

# ITIPART Customer Deployment

## Overview

This subskill provides comprehensive guidance for managing the ITIPART customer deployment on your OVH-hosted RKE2 infrastructure. It extends the `infra-k8s-manager` skill with ITIPART-specific configurations and best practices.

> **Parent Skill**: This is a subskill of `infra-k8s-manager`. All core infrastructure management follows the parent skill's guidelines.

## Quick Start

### Create ITIPART Namespace

```bash
# Create the dedicated namespace for ITIPART
kubectl create namespace itipart

# Verify creation
kubectl get namespaces | grep itipart
```

### Basic Deployment

```bash
# Apply ITIPART-specific Kubernetes resources
kubectl apply -f /workspace/2.erk-infra/app/itipart/kubernetes/ -n itipart

# Verify deployment
kubectl get all -n itipart
```

## Core Configuration

### Repository Information

- **Repository**: `fnfe`
- **Customer**: ITIPART (correct naming: "itipart")
- **Namespace**: `itipart`
- **Directory**: `2.erk-infra/app/itipart`

### Directory Structure

```
2.erk-infra/app/itipart/
├── README.md                  # Setup guide
├── DEPLOYMENT_COMMENTS.md     # Technical recommendations
├── terraform/
│   └── variables.tf           # Terraform configuration
└── kubernetes/
    ├── deployment.yaml        # Deployment manifest
    └── service.yaml           # Service manifest
```

## Terraform Configuration

### Variables

```hcl
# terraform/variables.tf
variable "cluster_ips" {
  type        = list(string)
  description = "List of cluster IP addresses for ITIPART deployment"
  default     = ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
}

variable "fnfe_image_tag" {
  type        = string
  description = "Docker image tag for fnfe repository"
  default     = "latest"
}

variable "replica_count" {
  type        = number
  description = "Number of replicas for ITIPART deployment"
  default     = 2
}
```

### Usage Example

```hcl
# Example resource using cluster_ips
resource "some_resource" "itipart" {
  count = length(var.cluster_ips)
  ip_address = var.cluster_ips[count.index]
  # ... other configuration
}
```

## Kubernetes Deployment

### Deployment Manifest

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: itipart-app
  namespace: itipart
spec:
  replicas: 2
  selector:
    matchLabels:
      app: itipart-app
  template:
    metadata:
      labels:
        app: itipart-app
    spec:
      containers:
      - name: itipart-app
        image: your-repo/fnfe:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1"
            memory: "1Gi"
```

### Service Manifest

```yaml
# kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: itipart-service
  namespace: itipart
spec:
  selector:
    app: itipart-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

## Deployment Strategies

### 1. Direct Image Updates

```bash
# Update to specific image tag
kubectl set image deployment/itipart-app itipart-app=your-repo/fnfe:new-tag -n itipart

# Monitor rollout
kubectl rollout status deployment/itipart-app -n itipart
```

### 2. ArgoCD Configuration

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: itipart-app
  namespace: argocd
spec:
  destination:
    namespace: itipart
    server: https://kubernetes.default.svc
  source:
    repoURL: https://gitlab.akretion.com/akretion/fnfe.git
    path: kubernetes/itipart
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 3. GitLab CI/CD

```yaml
# .gitlab-ci.yml template
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - docker build -t your-repo/fnfe:$CI_COMMIT_SHORT_SHA .
    - docker push your-repo/fnfe:$CI_COMMIT_SHORT_SHA

deploy-itipart:
  stage: deploy
  script:
    - kubectl set image deployment/itipart-app itipart-app=your-repo/fnfe:$CI_COMMIT_SHORT_SHA -n itipart
    - kubectl rollout status deployment/itipart-app -n itipart
  environment:
    name: production/itipart
```

## Security Configuration

### RBAC Setup

```yaml
# itipart-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: itipart-sa
  namespace: itipart
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: itipart-role
  namespace: itipart
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
```

### Network Policies

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: itipart-network-policy
  namespace: itipart
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: itipart
```

## Monitoring Setup

### Service Monitor

```yaml
# monitoring/service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: itipart-service-monitor
  namespace: itipart
spec:
  selector:
    matchLabels:
      app: itipart-app
  endpoints:
  - port: http
    interval: 30s
```

### Alert Rules

```yaml
# monitoring/alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: itipart-alerts
  namespace: itipart
spec:
  groups:
  - name: itipart.rules
    rules:
    - alert: ITIPARTHighErrorRate
      expr: rate(http_requests_total{status=~"5..",namespace="itipart"}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate for ITIPART application"
```

## Troubleshooting

### Common Commands

```bash
# Check pod status
kubectl get pods -n itipart

# View logs
kubectl logs -l app=itipart-app -n itipart --tail=100

# Describe deployment
kubectl describe deployment itipart-app -n itipart

# Check events
kubectl get events -n itipart --sort-by='.metadata.creationTimestamp'
```

### Rollback Procedures

```bash
# Rollback to previous revision
kubectl rollout undo deployment/itipart-app -n itipart

# Rollback to specific revision
kubectl rollout undo deployment/itipart-app --to-revision=2 -n itipart
```

## Integration with Parent Skill

This subskill extends `infra-k8s-manager` with:

- **Customer-specific namespace**: `itipart`
- **Repository integration**: `fnfe` repository
- **Deployment patterns**: ITIPART-specific configurations
- **Monitoring**: Custom alerts and service monitors

All core infrastructure management (cluster provisioning, DNS, IAM) follows the parent skill's guidelines documented in:
- `/provisioning/Cluster-Install_README.md`
- `/platform/iam/README.md`

## Best Practices

1. **Namespace Isolation**: Keep ITIPART resources in dedicated namespace
2. **Image Management**: Use semantic versioning for fnfe repository
3. **RBAC**: Follow least-privilege principle
4. **Monitoring**: Set up customer-specific alerts
5. **Documentation**: Maintain ITIPART-specific README

## Triggers

This subskill is invoked when you ask about:

- ITIPART customer deployment
- fnfe repository deployment
- itipart namespace management
- ITIPART-specific Kubernetes configurations
- ITIPART monitoring and alerts

For general infrastructure questions, the parent `infra-k8s-manager` skill handles:
- Cluster provisioning
- DNS management
- Developer onboarding
- Core Kubernetes operations

[Skill directory: /root/.hermes/skills/devops/infra-k8s-manager/itipart-deployment]
Resolve any relative paths in this skill against the parent skill directory.
