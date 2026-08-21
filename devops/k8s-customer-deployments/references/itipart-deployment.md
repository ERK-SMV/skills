# ITIPART Customer Deployment Reference

## Overview
This reference document provides comprehensive guidance for deploying and managing the ITIPART customer on Kubernetes clusters.

## Customer Information
- **Customer Name**: ITIPART (correct naming: "itipart")
- **Namespace**: `itipart`
- **Repository**: `fnfe`
- **Directory**: `2.erk-infra/app/itipart`

## Setup Instructions

### 1. Create Kubernetes Namespace

```bash
# Create the dedicated namespace for ITIPART
kubectl create namespace itipart

# Add labels for organization
kubectl label namespace itipart customer=itipart environment=production

# Verify namespace creation
kubectl get namespace itipart --show-labels
```

### 2. Terraform Configuration

**Key Variables**:
```hcl
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

**Usage Pattern**:
```hcl
# Corrected usage of cluster_ips
resource "some_resource" "name" {
  count = length(var.cluster_ips)
  ip_address = var.cluster_ips[count.index]
}
```

### 3. Kubernetes Deployment

**Deployment Manifest** (`kubernetes/deployment.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: itipart-app
  namespace: itipart
  labels:
    app: itipart-app
    customer: itipart
    repo: fnfe
spec:
  replicas: 2
  selector:
    matchLabels:
      app: itipart-app
  template:
    metadata:
      labels:
        app: itipart-app
        customer: itipart
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

**Service Manifest** (`kubernetes/service.yaml`):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: itipart-service
  namespace: itipart
  labels:
    app: itipart-app
    customer: itipart
spec:
  selector:
    app: itipart-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
  type: ClusterIP
```

### 4. Deployment Strategies

**Option A: Direct Image Updates**
```bash
# Update to new image tag
kubectl set image deployment/itipart-app itipart-app=your-repo/fnfe:new-tag -n itipart

# Verify rollout
kubectl rollout status deployment/itipart-app -n itipart
```

**Option B: ArgoCD Configuration**
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
    plugin:
      name: kustomize
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 5. CI/CD Pipeline

**GitLab CI Template**:
```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - docker build -t your-repo/fnfe:$CI_COMMIT_SHORT_SHA .
    - docker push your-repo/fnfe:$CI_COMMIT_SHORT_SHA
  only:
    - main

deploy-itipart:
  stage: deploy
  script:
    - kubectl set image deployment/itipart-app itipart-app=your-repo/fnfe:$CI_COMMIT_SHORT_SHA -n itipart
    - kubectl rollout status deployment/itipart-app -n itipart
  environment:
    name: production/itipart
    url: https://itipart.your-domain.com
  only:
    - main
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
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: itipart-rolebinding
  namespace: itipart
subjects:
- kind: ServiceAccount
  name: itipart-sa
  namespace: itipart
roleRef:
  kind: Role
  name: itipart-role
  apiGroup: rbac.authorization.k8s.io
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
    - podSelector: {}
```

## Monitoring Setup

### Prometheus ServiceMonitor
```yaml
# monitoring/service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: itipart-service-monitor
  namespace: itipart
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: itipart-app
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
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
      expr: rate(http_requests_total{status=~"5..",namespace="itipart"}[5m]) / rate(http_requests_total{namespace="itipart"}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
        customer: itipart
      annotations:
        summary: "High error rate for ITIPART application"
        description: "Error rate is {{ $value }} for ITIPART application"
```

## Deployment Checklist

- [ ] Create namespace: `kubectl create namespace itipart`
- [ ] Apply RBAC configuration
- [ ] Deploy Kubernetes resources
- [ ] Configure Terraform variables
- [ ] Set up CI/CD pipeline
- [ ] Configure monitoring and alerts
- [ ] Set up DNS records
- [ ] Configure ingress/load balancer
- [ ] Test deployment and rollback procedures

## Best Practices for ITIPART

1. **Namespace Isolation**: Keep ITIPART resources in dedicated namespace
2. **Image Management**: Use semantic versioning for fnfe repository
3. **Security**: Follow least-privilege principle for RBAC
4. **Monitoring**: Set up comprehensive monitoring from day one
5. **Documentation**: Maintain up-to-date documentation in GitLab WIKI
6. **CI/CD**: Automate deployment pipeline for consistency

## Troubleshooting

### Common Issues and Solutions

**Image Pull Errors**:
```bash
kubectl describe pod <pod-name> -n itipart
kubectl logs <pod-name> -n itipart
```

**Service Not Accessible**:
```bash
kubectl get svc -n itipart
kubectl get endpoints -n itipart
kubectl describe svc itipart-service -n itipart
```

**Deployment Rollout Stuck**:
```bash
kubectl rollout status deployment/itipart-app -n itipart
kubectl get events -n itipart --sort-by='.metadata.creationTimestamp'
```

This reference provides a complete template for ITIPART customer deployment that can be adapted to your specific requirements.