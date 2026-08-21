# n8n (test)

Test-only n8n deployment in the `ai-tools` namespace, for the upcoming Hermes n8n MCP
integration. Queue mode with a single worker, backed by a dedicated Postgres and Redis
(both plain manifests here, not chart dependencies - the official chart requires external
Postgres/Redis, it doesn't bundle them).

## Components

| File | Purpose |
|------|---------|
| `postgres.yaml` | Standalone Postgres 16 (StatefulSet + headless Service), db/user `n8n` |
| `redis.yaml` | Standalone Redis 7 (Deployment + Service), no persistence, no auth - queue broker only |
| `values.yaml` | Helm values for the official n8n chart |

n8n itself is **not** a manifest here - it's installed via the official OCI chart:

```bash
helm install n8n oci://ghcr.io/n8n-io/n8n-helm-chart/n8n --version 1.11.0 -n ai-tools -f values.yaml
```

Chart source: https://github.com/n8n-io/n8n-hosting/tree/main/charts/n8n

## Required secrets (create before installing - not committed here)

```bash
kubectl create secret generic n8n-db-password -n ai-tools \
  --from-literal=password="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9')"

kubectl create secret generic n8n-core-secrets -n ai-tools \
  --from-literal=N8N_ENCRYPTION_KEY="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9')" \
  --from-literal=N8N_HOST="n8n-main.ai-tools.svc.cluster.local" \
  --from-literal=N8N_PORT="5678" \
  --from-literal=N8N_PROTOCOL="http"
```

`N8N_ENCRYPTION_KEY` must stay stable across reinstalls or previously-saved credentials
inside n8n become unreadable - back it up if this stops being disposable test infra.

## Access

```bash
kubectl port-forward -n ai-tools svc/n8n-main 5678:5678
# then open http://localhost:5678
```

Internal DNS for other in-cluster clients (e.g. Hermes): `http://n8n-main.ai-tools.svc.cluster.local:5678`

## Verification

```bash
kubectl get pods -n ai-tools -l app.kubernetes.io/instance=n8n
kubectl exec -n ai-tools deployment/hermes -- curl -s http://n8n-main.ai-tools.svc.cluster.local:5678/healthz
```
