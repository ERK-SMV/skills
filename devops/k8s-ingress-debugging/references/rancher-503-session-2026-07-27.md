# Rancher GUI 503 Troubleshooting - Session Reference

**Session Date:** 2026-07-27  
**Issue:** Rancher GUI at `http://mgmt.infra.flows.cab` returning 503 Service Unavailable  
**Root Cause:** No ingress configured for hostname, falling through to default backend routing to `default/odoo-18:8069` (no endpoints)

---

## Problem Analysis

### Initial Symptoms
- User reported: "anlyse the logs, the ingress of the GUI rancher and explain me why the GUI is down: http://mgmt.infra.flows.cab"
- `curl -k https://mgmt.infra.flows.cab` returned 503 from nginx
- All 4 cluster nodes (37.59.105.146, 37.187.219.194, 51.75.140.108, 51.75.140.93) returned 503

### Investigation Steps Performed

1. **Cluster Access:**
   - Found we were running inside a Kubernetes pod with service account `ai-tools:hermes`
   - Downloaded kubectl to `/root/kubectl` (v1.36.3)
   - Confirmed access to cluster API at `10.43.0.1:443`

2. **Cluster Status:**
   - All 4 nodes Ready: vps-152eeec0, vps-8db89036, vps-df7e5e4d, vps-e085cff3
   - Rancher pods running in `cattle-system`: rancher-6ccfd74897-bj86b (1/1 Running)

3. **Service Check:**
   - Rancher service exists: `cattle-system/rancher` (ClusterIP: 10.43.17.226, ports 80/443)
   - Rancher health endpoint: `curl http://localhost:80/healthz` → 200 OK
   - Rancher HTTPS: `curl -sk https://10.43.17.226/` → 200 OK

4. **Ingress Investigation:**
   - Permission denied listing ingresses in `cattle-system` namespace
   - Found ingresses in `ai-tools` namespace only
   - Checked nginx controller configuration directly

5. **Nginx Configuration Analysis:**
   ```bash
   kubectl exec -n kube-system rke2-ingress-nginx-controller-8hgpt -- nginx -T
   ```
   - Found configured ingresses for:
     - `infra-mgmt.legalides.eu` → `cattle-system/rancher:80`
     - `mgmt.infra.akretion.cab` → `cattle-system/rancher:80`
   - **NOT found:** `mgmt.infra.flows.cab`
   - Found default backend routing `/` to `default/odoo-18:8069`

6. **Default Backend Issue:**
   - `kubectl get endpoints -n default odoo-18` → `<none>`
   - Service exists but has NO ENDPOINTS
   - Therefore: requests to unmatched hostnames → default backend → odoo-18 (no endpoints) → **503**

---

## Root Cause

**The request flow:**
```
User Request: http://mgmt.infra.flows.cab/
  ↓
No ingress matches hostname
  ↓
Nginx default backend (server_name _)
  ↓
Routes to: default/odoo-18:8069
  ↓
Service has NO ENDPOINTS
  ↓
503 Service Unavailable ✗
```

---

## Solution Implemented

### Required: Create Ingress for mgmt.infra.flows.cab

**File: `rancher-mgmt-flows-ingress.yaml`**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rancher-mgmt-flows
  namespace: cattle-system
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
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

### Required: Create TLS Certificate

**File: `rancher-mgmt-flows-certificate.yaml`**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-rancher-mgmt-flows
  namespace: cattle-system
spec:
  secretName: tls-rancher-mgmt-flows
  issuerRef:
    name: rancher
    kind: Issuer
    group: cert-manager.io
  commonName: mgmt.infra.flows.cab
  dnsNames:
  - mgmt.infra.flows.cab
```

### Apply Configuration
```bash
kubectl apply -f rancher-mgmt-flows-certificate.yaml
kubectl apply -f rancher-mgmt-flows-ingress.yaml
```

---

## Migration: Replace Old Hostnames

**User requested:** Replace `infra-mgmt.legalides.eu` and `mgmt.infra.akretion.cab` with `mgmt.infra.flows.cab`

### Steps:
1. Create new ingress for `mgmt.infra.flows.cab` (above)
2. Create new TLS certificate (above)
3. Remove old ingresses:
   ```bash
   kubectl delete ingress -n cattle-system rancher
   kubectl delete ingress -n cattle-system rancher-infra
   ```
4. Remove old TLS:
   ```bash
   kubectl delete certificate -n cattle-system tls-rancher-ingress
   kubectl delete secret -n cattle-system tls-rancher-ingress
   ```
5. Update DNS (if needed - currently resolves correctly)
6. Verify: `curl -k https://mgmt.infra.flows.cab -v`

---

## Existing Configuration Found

### TLS Secrets in cattle-system
- `tls-rancher` - Current Rancher TLS
- `tls-rancher-ingress` - For `infra-mgmt.legalides.eu` (cert-manager managed)
- `tls-rancher-internal` - For internal Rancher communication
- `tls-rancher-internal-ca` - CA for internal certs

### Ingress Controller
- **Namespace:** `kube-system`
- **Controller:** `rke2-ingress-nginx` (Helm chart v4.10.101)
- **Pods:** 4 replicas (rke2-ingress-nginx-controller-*)
- **Service:** `rke2-ingress-nginx-controller` (ClusterIP)

### Rancher Deployment
- **Image:** `rancher/rancher:v2.14.2`
- **Args:** `--no-cacerts`, `--http-listen-port=80`, `--https-listen-port=443`, `--add-local=true`
- **Probes:** HTTP GET `http://:80/healthz` (liveness, readiness, startup)
- **Environment:**
  - `CATTLE_NAMESPACE=cattle-system`
  - `CATTLE_PEER_SERVICE=rancher`
  - `IMPERATIVE_API_DIRECT=true`

---

## Nginx Default Backend Configuration

**From: `kubectl exec -n kube-system rke2-ingress-nginx-controller-8hgpt -- nginx -T`**

```nginx
server {
    server_name _ ;
    
    listen 80 default_server reuseport backlog=4096 ;
    listen [::]:80 default_server reuseport backlog=4096 ;
    listen 443 default_server reuseport backlog=4096 ssl;
    listen [::]:443 default_server reuseport backlog=4096 ssl;
    
    location / {
        set $namespace      "default";
        set $ingress_name   "odoo-18";
        set $service_name   "odoo-18";
        set $service_port   "8069";
        ...
        proxy_pass http://upstream_balancer;
    }
    
    location /websocket/ {
        set $namespace      "default";
        set $ingress_name   "odoo-18";
        set $service_name   "odoo-18";
        set $service_port   "8072";
        ...
    }
}
```

**Problem:** Both locations route to `default/odoo-18` which has no endpoints.

---

## Verification Commands

```bash
# Check Rancher is running
kubectl get pods -n cattle-system -l app=rancher

# Check Rancher service
kubectl get svc -n cattle-system rancher

# Check if odoo-18 has endpoints (should be empty)
kubectl get endpoints -n default odoo-18

# Test Rancher directly (from within cluster)
kubectl exec -n cattle-system rancher-6ccfd74897-bj86b -- curl -sk https://10.43.17.226/

# Check nginx config for hostname
kubectl exec -n kube-system rke2-ingress-nginx-controller-8hgpt -- nginx -T | grep mgmt.infra.flows.cab

# Check nginx logs for requests
kubectl logs -n kube-system rke2-ingress-nginx-controller-8hgpt | grep mgmt.infra.flows.cab
```

---

## Lessons Learned

1. **Always check if ingress exists** - Don't assume hostname is configured
2. **Default backend is dangerous** - Unmatched hostnames route to default, which may have no endpoints
3. **Check endpoints, not just services** - A service without endpoints causes 503
4. **Permission limitations matter** - Service accounts may not have access to all namespaces
5. **Nginx config is authoritative** - Use `nginx -T` to see actual routing, not just kubectl
6. **Rancher health endpoint** - `http://localhost:80/healthz` returns 200 when healthy
7. **Rancher redirects HTTP→HTTPS** - Always use HTTPS for Rancher GUI

---

## Tools Used

- `kubectl` (downloaded v1.36.3)
- `curl` (for testing endpoints)
- `grep`/`awk` (for log analysis)
- In-cluster service account: `ai-tools:hermes`

---

## Related Files

- **Rancher Service:** `cattle-system/rancher` (ClusterIP: 10.43.17.226)
- **Rancher Pod:** `rancher-6ccfd74897-bj86b` (IP: 10.42.0.128)
- **Ingress Controller:** `kube-system/rke2-ingress-nginx-controller-*`
- **DNS:** mgmt.infra.flows.cab → 37.59.105.146, 37.187.219.194, 51.75.140.108, 51.75.140.93
