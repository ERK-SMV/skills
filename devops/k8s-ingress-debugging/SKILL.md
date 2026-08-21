---
name: k8s-ingress-debugging
description: Debug Kubernetes ingress routing and 503 errors on RKE2.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [kubernetes, ingress, nginx, debugging, rke2, rancher, troubleshooting]
    related_skills: [infra-k8s-manager, systematic-debugging]
---

# Kubernetes Ingress Debugging

**Use when** diagnosing 503 errors, routing issues, or nginx ingress controller problems on RKE2 clusters.

## Overview

Ingress routing issues are common in Kubernetes clusters, especially when:
- New hostnames are added without corresponding ingress resources
- Default backends route to services with no endpoints
- TLS certificates are misconfigured
- Nginx controller has stale configuration

This skill provides systematic debugging patterns for ingress-related issues.

---

## When to Use

- HTTP 503 Service Unavailable errors
- Requests routing to wrong backend services
- Ingress controller not picking up new configurations
- TLS/SSL certificate issues
- Default backend misconfiguration

---

## Debugging Workflow

### Phase 1: Verify the Symptom

**Reproduce the exact issue:**
```bash
# Test the failing endpoint
curl -v http://mgmt.infra.flows.cab/
curl -kv https://mgmt.infra.flows.cab/

# Check HTTP status code
curl -s -o /dev/null -w "%{http_code}" http://mgmt.infra.flows.cab/
```

**Expected:** 200 OK
**Actual:** 503 Service Unavailable

---

### Phase 2: Check Ingress Configuration

**Does an ingress exist for this hostname?**
```bash
# List all ingresses (requires appropriate permissions)
kubectl get ingress -A | grep mgmt.infra.flows.cab

# If no results, the hostname has no ingress
```

**If you get "Forbidden" errors:**
- Your service account lacks permissions to list ingresses in certain namespaces
- Try specific namespaces you have access to
- Ask admin to check for you

---

### Phase 3: Check Nginx Ingress Controller Configuration

**Inspect the running nginx configuration:**
```bash
# Get nginx controller pod name
kubectl get pods -n kube-system -l app.kubernetes.io/name=rke2-ingress-nginx

# Check if hostname is in nginx config
kubectl exec -n kube-system <ingress-pod> -- nginx -T | grep mgmt.infra.flows.cab

# If no results, the hostname is NOT configured
```

**Check default backend configuration:**
```bash
# View the default server block
kubectl exec -n kube-system <ingress-pod> -- nginx -T | grep -A 50 "server_name _ ;"
```

**Look for:**
- Default backend routing to unexpected services
- Services with no endpoints (causes 503)

---

### Phase 4: Check Backend Service Health

**If ingress exists, check the backend service:**
```bash
# Get the service from ingress
kubectl get ingress -n <namespace> <ingress-name> -o yaml | grep service.name

# Check service exists
kubectl get svc -n <namespace> <service-name>

# Check service has endpoints
kubectl get endpoints -n <namespace> <service-name>
```

**If ENDPOINTS is `<none>`:**
- No pods are running for this service
- Check deployment: `kubectl get pods -n <namespace> -l <selector>`
- Check pod status: `kubectl describe pod -n <namespace> <pod-name>`

---

### Phase 5: Check Nginx Controller Logs

**Look for routing errors:**
```bash
kubectl logs -n kube-system <ingress-pod> | grep -E "(503|error|fail|upstream)" | tail -50

# Filter for specific hostname
kubectl logs -n kube-system <ingress-pod> | grep mgmt.infra.flows.cab
```

**Common errors:**
- `no upstream available` - Service has no endpoints
- `upstream sent duplicate header` - Backend application issue
- `watcher channel closed` - Controller connectivity issue

---

## Common Issues & Solutions

### Issue 1: No Ingress for Hostname

**Symptoms:**
- 503 error for new hostname
- Hostname not found in nginx config

**Solution:**
Create an ingress resource for the hostname:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  namespace: my-namespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: mgmt.infra.flows.cab
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
  tls:
  - hosts:
    - mgmt.infra.flows.cab
    secretName: my-tls-secret
```

---

### Issue 2: Default Backend Routes to Wrong Service

**Symptoms:**
- 503 error for any unmatched hostname
- Nginx default server routes to service with no endpoints

**Diagnosis:**
```bash
kubectl exec -n kube-system <ingress-pod> -- nginx -T | grep -A 30 "server_name _ ;"
```

**Look for:**
```nginx
location / {
    set $namespace      "default";
    set $service_name   "odoo-18";
    set $service_port   "8069";
    ...
}
```

**Solution:**
- Create proper ingress for your hostname
- OR configure a proper default backend with endpoints

---

### Issue 3: Service Has No Endpoints

**Symptoms:**
- 503 error
- `kubectl get endpoints` shows `<none>`

**Diagnosis:**
```bash
kubectl get endpoints -n <namespace> <service-name>
kubectl get pods -n <namespace> -l <selector>
```

**Solutions:**
1. **Deployment not running:**
   ```bash
   kubectl get deployments -n <namespace>
   kubectl describe deployment -n <namespace> <deployment-name>
   ```

2. **Pods not ready:**
   ```bash
   kubectl get pods -n <namespace>
   kubectl describe pod -n <namespace> <pod-name>
   kubectl logs -n <namespace> <pod-name>
   ```

3. **Wrong selector:**
   ```bash
   # Compare service selector with pod labels
   kubectl get svc -n <namespace> <service-name> -o yaml | grep selector
   kubectl get pods -n <namespace> --show-labels
   ```

---

### Issue 4: TLS Certificate Problems

**Symptoms:**
- SSL handshake errors
- Certificate not trusted
- Mixed content warnings

**Diagnosis:**
```bash
# Check TLS secret exists
kubectl get secret -n <namespace> <tls-secret-name>

# Check certificate in secret
kubectl get secret -n <namespace> <tls-secret-name> -o yaml | grep tls.crt

# Check cert-manager certificate (if used)
kubectl get certificate -n <namespace>
```

**Solution:**
- Ensure TLS secret exists and is valid
- Ensure certificate covers the hostname
- Check cert-manager issuer is working

---

## RKE2-Specific Notes

### Nginx Ingress Controller

RKE2 uses the `rke2-ingress-nginx` controller deployed in `kube-system` namespace.

**Controller pods:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=rke2-ingress-nginx
```

**Controller service:**
```bash
kubectl get svc -n kube-system rke2-ingress-nginx-controller
```

### Default Backend Behavior

RKE2's nginx controller has a default backend that:
- Handles requests for hostnames without specific ingress rules
- Routes to a configurable default service
- Returns 503 if the default service has no endpoints

**Check current default backend:**
```bash
kubectl exec -n kube-system <ingress-pod> -- nginx -T | grep -B 5 -A 20 "server_name _ ;"
```

---

## Rancher-Specific Debugging

### Rancher GUI 503 Error

**Symptoms:**
- `https://mgmt.infra.flows.cab` returns 503
- Rancher pods are running
- Rancher service exists

**Root Cause:**
No ingress configured for `mgmt.infra.flows.cab`, requests fall through to default backend which routes to `default/odoo-18:8069` (no endpoints).

**Solution:**
Create ingress in `cattle-system` namespace:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rancher-mgmt-flows
  namespace: cattle-system
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    cert-manager.io/cluster-issuer: "letsencrypt-production"
    field.cattle.io/publicEndpoints: >-
      [{"addresses":["37.187.219.194","37.59.105.146","51.75.140.108","51.75.140.93"],
        "port":443,"protocol":"HTTPS","serviceName":"cattle-system:rancher",
        "ingressName":"cattle-system:rancher-mgmt-flows","hostname":"mgmt.infra.flows.cab",
        "path":"/","allNodes":false}]
spec:
  ingressClassName: nginx
  rules:
  - host: mgmt.infra.flows.cab
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: rancher
            port:
              number: 443
  tls:
  - hosts:
    - mgmt.infra.flows.cab
    secretName: tls-rancher-mgmt-flows
```

**Verify Rancher health:**
```bash
kubectl exec -n cattle-system <rancher-pod> -- curl -s http://localhost:80/healthz
# Should return: 200
```

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Check ingress exists | `kubectl get ingress -A \| grep <hostname>` |
| Check nginx config | `kubectl exec -n kube-system <pod> -- nginx -T \| grep <hostname>` |
| Check service endpoints | `kubectl get endpoints -n <ns> <svc>` |
| Check pod logs | `kubectl logs -n <ns> <pod>` |
| Check nginx logs | `kubectl logs -n kube-system <ingress-pod>` |
| Test from within cluster | `kubectl exec <pod> -- curl -s <service-ip>:<port>` |
| Check DNS resolution | `nslookup <hostname>` or `dig <hostname>` |

---

## Pitfalls

1. **Assuming ingress exists** - Always verify with `kubectl get ingress -A`
2. **Ignoring default backend** - Unmatched hostnames go to default backend
3. **Not checking endpoints** - Service without endpoints causes 503
4. **Permission issues** - Service accounts may not have access to all namespaces
5. **Stale nginx config** - After creating ingress, wait for controller to update
6. **Wrong port** - Backend service port must match ingress configuration
7. **Missing TLS** - HTTPS without TLS secret causes errors

---

## Verification Checklist

- [ ] Ingress resource exists for the hostname
- [ ] Ingress is in the correct namespace
- [ ] Backend service exists and has endpoints
- [ ] TLS secret exists (for HTTPS)
- [ ] Nginx controller has updated configuration
- [ ] DNS resolves to cluster node IPs
- [ ] Service is accessible from within cluster
- [ ] No errors in nginx controller logs

---

## Reference Files

- [`references/rancher-503-session-2026-07-27.md`](references/rancher-503-session-2026-07-27.md) - Complete session reference for Rancher GUI 503 troubleshooting with exact commands, root cause analysis, and solution

---

## Related Skills

- `infra-k8s-manager` - RKE2 infrastructure management
- `systematic-debugging` - General debugging methodology
