---
name: k8s-customer-deployments
description: Manage customer Kubernetes deployments with Terraform.
version: 1.0.0
triggers:
  - customer deployment
  - kubernetes namespace setup
  - terraform customer configuration
  - argocd customer application
  - ci/cd pipeline setup
---

# Kubernetes Customer Deployments

## Overview

This skill provides comprehensive guidance for setting up and managing customer-specific deployments on Kubernetes clusters. It covers namespace creation, Terraform configuration, Kubernetes manifests, ArgoCD setup, and CI/CD pipeline configuration.

## Table of Contents

1. [Customer Deployment Pattern](#customer-deployment-pattern)
2. [Namespace Management](#namespace-management)
3. [Terraform Configuration](#terraform-configuration)
4. [Kubernetes Manifests](#kubernetes-manifests)
5. [Deployment Strategies](#deployment-strategies)
6. [CI/CD Pipeline Setup](#ci-cd-pipeline-setup)
7. [Security Configuration](#security-configuration)
8. [Monitoring Setup](#monitoring-setup)
9. [ITIPART Example Deployment](#itipart-example-deployment)
10. [Best Practices](#best-practices)

## Customer Deployment Pattern

### Standard Structure

```
2.erk-infra/app/<customer>/
├── README.md                  # Customer-specific documentation
├── terraform/
│   ├── main.tf               # Terraform configuration
│   ├── variables.tf          # Variable definitions
│   └── outputs.tf            # Output definitions
├── kubernetes/
│   ├── deployment.yaml       # Deployment manifest
│   ├── service.yaml          # Service manifest
│   └── ingress.yaml          # Ingress configuration
├── argocd/
│   └── application.yaml      # ArgoCD configuration
└── monitoring/
    ├── service-monitor.yaml   # Prometheus monitor
    └── alerts.yaml            # Alert rules
```

### Workflow

1. **Create namespace** for customer isolation
2. **Configure Terraform** with customer-specific variables
3. **Create Kubernetes manifests** for deployment and service
4. **Set up deployment strategy** (direct kubectl, ArgoCD, or CI/CD)
5. **Configure monitoring** and alerting
6. **Document** customer-specific requirements

## Namespace Management

### Create Customer Namespace

```bash
# Create namespace for customer
kubectl create namespace <customer-name>

# Add labels for organization
kubectl label namespace <customer-name> 
  customer=<customer-name> 
  environment=production

# Verify namespace
kubectl get namespace <customer-name> --show-labels
```

### Namespace Best Practices

- Use lowercase names (e.g., `itipart`, `acme-corp`)
- Add descriptive labels for filtering
- Set resource quotas to prevent resource hogging
- Configure network policies for isolation

## Terraform Configuration

### Variable Structure

```hcl
# variables.tf
variable "cluster_ips" {
  type        = list(string)
  description = "List of cluster IP addresses"
  default     = ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
}

variable "image_tag" {
  type        = string
  description = "Docker image tag"
  default     = "latest"
}

variable "replica_count" {
  type        = number
  description = "Number of replicas"
  default     = 2
}

variable "customer_name" {
  type        = string
  description = "Customer name for labeling"
}
```

### Output Configuration

```hcl
# outputs.tf
output "service_endpoint" {
  description = "Service endpoint URL"
  value       = "${var.customer_name}-service.${var.customer_name}.svc.cluster.local"
}

output "cluster_ips" {
  description = "Cluster IPs used for deployment"
  value       = var.cluster_ips
}
```

## Kubernetes Manifests

### Deployment Template

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${customer_name}-app
  namespace: ${customer_name}
  labels:
    app: ${customer_name}-app
    customer: ${customer_name}
spec:
  replicas: ${replica_count}
  selector:
    matchLabels:
      app: ${customer_name}-app
  template:
    metadata:
      labels:
        app: ${customer_name}-app
        customer: ${customer_name}
    spec:
      containers:
      - name: ${customer_name}-app
        image: ${repository}/${image_name}:${image_tag}
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

### Service Template

```yaml
# kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${customer_name}-service
  namespace: ${customer_name}
  labels:
    app: ${customer_name}-app
    customer: ${customer_name}
spec:
  selector:
    app: ${customer_name}-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
  type: ClusterIP
```

## Deployment Strategies

### Direct Kubectl Updates

```bash
# Update image directly
kubectl set image deployment/${customer_name}-app 
  ${customer_name}-app=${repository}/${image_name}:${new_tag} 
  -n ${customer_name}

# Verify rollout
kubectl rollout status deployment/${customer_name}-app -n ${customer_name}
```

### ArgoCD Configuration

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${customer_name}-app
  namespace: argocd
spec:
  destination:
    namespace: ${customer_name}
    server: https://kubernetes.default.svc
  source:
    repoURL: ${git_repository}
    path: kubernetes/${customer_name}
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

### CI/CD Pipeline (GitLab)

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - docker build -t ${repository}/${image_name}:${CI_COMMIT_SHORT_SHA} .
    - docker push ${repository}/${image_name}:${CI_COMMIT_SHORT_SHA}
  only:
    - main

deploy-${customer_name}:
  stage: deploy
  script:
    - kubectl set image deployment/${customer_name}-app 
      ${customer_name}-app=${repository}/${image_name}:${CI_COMMIT_SHORT_SHA} 
      -n ${customer_name}
    - kubectl rollout status deployment/${customer_name}-app -n ${customer_name}
  environment:
    name: production/${customer_name}
    url: https://${customer_name}.your-domain.com
  only:
    - main
```

## Security Configuration

### RBAC Setup

```yaml
# rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${customer_name}-sa
  namespace: ${customer_name}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${customer_name}-role
  namespace: ${customer_name}
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${customer_name}-rolebinding
  namespace: ${customer_name}
subjects:
- kind: ServiceAccount
  name: ${customer_name}-sa
  namespace: ${customer_name}
roleRef:
  kind: Role
  name: ${customer_name}-role
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${customer_name}-network-policy
  namespace: ${customer_name}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ${customer_name}
    - podSelector: {}
```

## Monitoring Setup

### Prometheus ServiceMonitor

```yaml
# monitoring/service-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ${customer_name}-service-monitor
  namespace: ${customer_name}
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: ${customer_name}-app
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
  name: ${customer_name}-alerts
  namespace: ${customer_name}
spec:
  groups:
  - name: ${customer_name}.rules
    rules:
    - alert: ${customer_name}HighErrorRate
      expr: rate(http_requests_total{status=~"5..",namespace="${customer_name}"}[5m]) / rate(http_requests_total{namespace="${customer_name}"}[5m]) > 0.1
      for: 5m
      labels:
        severity: warning
        customer: ${customer_name}
      annotations:
        summary: "High error rate for ${customer_name} application"
        description: "Error rate is {{ $value }} for ${customer_name} application"
```

## ITIPART Example Deployment

### Customer Information

- **Customer**: ITIPART (correct naming: "itipart")
- **Namespace**: `itipart`
- **Repository**: `fnfe`
- **Image**: `your-repo/fnfe:tag`

### Setup Commands

```bash
# Create namespace
kubectl create namespace itipart

# Apply RBAC
kubectl apply -f rbac.yaml -n itipart

# Deploy application
kubectl apply -f kubernetes/ -n itipart

# Verify deployment
kubectl get all -n itipart
```

### Terraform Variables

```hcl
variable "cluster_ips" {
  type        = list(string)
  description = "Cluster IPs for ITIPART deployment"
  default     = ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
}

variable "fnfe_image_tag" {
  type        = string
  description = "FNFE repository image tag"
  default     = "latest"
}
```

### Deployment Manifest

```yaml
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
```

## Best Practices

### Deployment

1. **Namespace Isolation**: Always use dedicated namespaces for customers
2. **Resource Limits**: Set appropriate resource requests and limits
3. **Image Management**: Use semantic versioning for reproducible deployments
4. **Rollback Strategy**: Test rollback procedures before production
5. **Health Checks**: Configure proper liveness and readiness probes

### Security

1. **Least Privilege**: Follow principle of least privilege for RBAC
2. **Network Isolation**: Use network policies to restrict traffic
3. **Secret Management**: Never store secrets in version control
4. **Pod Security**: Apply pod security standards
5. **Regular Audits**: Schedule regular security audits

### Monitoring

1. **Comprehensive Metrics**: Monitor all critical components
2. **Alert Thresholds**: Set appropriate alert thresholds
3. **Logging**: Centralize logs for easy troubleshooting
4. **Tracing**: Implement distributed tracing for complex systems
5. **SLOs**: Define and monitor service level objectives

## Troubleshooting

### Common Issues and Solutions

**Image Pull Errors**:
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Service Not Accessible**:
```bash
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace>
kubectl describe svc <service-name> -n <namespace>
```

**Deployment Rollout Stuck**:
```bash
kubectl rollout status deployment/<deployment-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp'
```

**Resource Constraints**:
```bash
kubectl top pods -n <namespace>
kubectl describe nodes | grep -A 10 "Allocated resources"
```

## Triggers

This skill is automatically invoked when you ask about:

- Customer-specific Kubernetes deployments
- Namespace setup for customers
- Terraform configuration for customer deployments
- ArgoCD application setup
- CI/CD pipeline configuration
- Multi-tenant Kubernetes patterns
- Customer isolation strategies
- Deployment automation for specific customers

## Usage Examples

| Question | Solution |
|----------|----------|
| How do I set up a new customer deployment? | See [Customer Deployment Pattern](#customer-deployment-pattern) |
| What's the best way to isolate customer resources? | See [Namespace Management](#namespace-management) |
| How to configure Terraform for customer deployments? | See [Terraform Configuration](#terraform-configuration) |
| What deployment strategies are available? | See [Deployment Strategies](#deployment-strategies) |
| How to set up monitoring for a customer? | See [Monitoring Setup](#monitoring-setup) |
| Can you show me the ITIPART example? | See [ITIPART Example Deployment](#itipart-example-deployment) |
