# PlantUML Server for AI-Tools Namespace

This deployment provides a PlantUML server for generating diagrams and schemas that can be used by Hermes Agent and other tools in the `ai-tools` namespace.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ai-tools namespace                      │
│                                                              │
│  ┌─────────────┐         ┌─────────────┐                  │
│  │   Hermes    │────────►│ PlantUML    │                  │
│  │   Agent     │         │ Server      │                  │
│  │             │◄────────┤             │                  │
│  └─────────────┘         └─────────────┘                  │
│       │                                             │        │
│       │                     ┌───────────────────────┤        │
│       ▼                     ▼                           ▼        │
│  ┌─────────────────────────────────────────────────────┐  │
│  │               Kubernetes ClusterIP Network           │  │
│  │  plantuml-service.ai-tools.svc.cluster.local:80     │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

Hermes Agent can access PlantUML via:
- **Internal DNS**: `http://plantuml-service.ai-tools.svc.cluster.local:80`
- **Ingress**: `http://plantuml.ai-tools.svc.cluster.local` (if ingress is configured)

## Files

| File | Purpose |
|------|---------|
| `deployment.yaml` | PlantUML server deployment |
| `service.yaml` | ClusterIP service for internal access |
| `ingress.yaml` | Ingress for external/internal DNS access |
| `kustomization.yaml` | Kustomize configuration for easy deployment |

## Deployment

### Option 1: Deploy with Kustomize (Recommended)

```bash
kubectl apply -k /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/plantuml/
```

### Option 2: Deploy Individual Files

```bash
kubectl apply -f /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/plantuml/deployment.yaml
kubectl apply -f /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/plantuml/service.yaml
kubectl apply -f /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/plantuml/ingress.yaml
```

## Configuration for Hermes Agent

### Do NOT register this as an MCP server

`plantuml-service` is a plain REST API, not an MCP-protocol endpoint. `hermes mcp add plantuml --url http://plantuml-service...` fails the MCP handshake (`Content-Type: text/html`, not a valid MCP response) — confirmed 2026-07-26.

### Direct call (confirmed working)

Hermes calls the service directly via its own terminal tool:

```bash
curl -s -X POST http://plantuml-service.ai-tools.svc.cluster.local/png \
  -H "Content-Type: text/plain" \
  --data-binary @- -o /tmp/diagram.png <<'EOF'
@startuml
Alice -> Bob : Hello
@enduml
EOF
```

This is documented as a persistent Hermes skill at `/root/.hermes/skills/project-mgmt/plantuml/SKILL.md` (on the PVC, survives pod restarts — not the ephemeral `/usr/local/lib/hermes-agent/optional-skills` reinstalled fresh on every pod start). See also the `infra-architecture-diagram` skill, which routes between this, the bundled `architecture-diagram` skill, and `marp` depending on what's needed.

### Usage Examples from Hermes

```
# Generate a diagram
plantuml @startuml
Alice -> Bob : Authentication Request
Bob --> Alice : Authentication Response
@enduml

# Generate and save a diagram
plantuml @startuml
class Car
class Driver
Driver -> Car : drives
@enduml
save as class-diagram.png
```

## PlantUML Server Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Web interface (redirects to diagram page) |
| `/plantuml/png/{diagram}` | GET | Render diagram as PNG |
| `/plantuml/svg/{diagram}` | GET | Render diagram as SVG |
| `/plantuml/txt/{diagram}` | GET | Return diagram as text |

Note: The PlantUML server uses base64-encoded diagram definitions in the URL path.

### Example API Call

```bash
# Direct API call using POST with text diagram
curl -X POST http://plantuml-service.ai-tools.svc.cluster.local/png \
  -H "Content-Type: text/plain" \
  -d "@startuml
Alice -> Bob : Hello
@enduml"

# Or using GET with encoded diagram (URL-encoded)
DIAGRAM=$(echo "@startuml
Alice -> Bob : Hello
@enduml" | base64 -w 0)
curl "http://plantuml-service.ai-tools.svc.cluster.local/plantuml/png/$DIAGRAM"
```

## Customization

### Change the Image

Edit `deployment.yaml` and change the image:
```yaml
image: plantuml/plantuml-server:jetty  # Default
# or
image: plantuml/plantuml-server:tomcat
```

### Resource Limits

Adjust CPU/memory in `deployment.yaml` based on your workload:
```yaml
resources:
  requests:
    cpu: 200m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### Ingress Configuration

Edit `ingress.yaml` to:
1. Change the `ingressClassName` to match your cluster
2. Change the `host` to your desired domain
3. Add TLS configuration if needed

Common ingress classes:
- `nginx` - For Nginx Ingress Controller
- `traefik` - For Traefik
- `ovh` - For OVH-managed ingress

## Verification

### Check Deployment Status
```bash
kubectl get pods -n ai-tools -l app=plantuml-server
kubectl get svc -n ai-tools -l app=plantuml-server
kubectl get ingress -n ai-tools -l app=plantuml-server
```

### Test the Service
```bash
# From within the cluster (using kubectl exec)
kubectl exec -it -n ai-tools deployment/hermes -- curl -X POST \
  http://plantuml-service:80/png \
  -H "Content-Type: text/plain" \
  -d "@startuml
Alice -> Bob : Test
@enduml" \
  --output /tmp/test-diagram.png

# Or via port-forward for local testing
kubectl port-forward -n ai-tools svc/plantuml-service 8080:80
# Then open http://localhost:8080 in your browser
```

### Test from Hermes
```bash
kubectl exec -it -n ai-tools deployment/hermes -- \
  /usr/local/lib/hermes-agent/venv/bin/hermes -z "Create a PlantUML diagram of a Kubernetes pod with containers"
```

## Troubleshooting

### Image Pull Errors
If you get `ImagePullBackOff`:
```bash
# Check the image exists
kubectl get pods -n ai-tools -l app=plantuml-server
kubectl describe pod -n ai-tools <plantuml-pod-name>

# Try a different image tag
kubectl set image -n ai-tools deployment/plantuml-server plantuml=plantuml/plantuml-server:tomcat
```

### Service Not Reachable
```bash
# Check service endpoint
kubectl get endpoints -n ai-tools plantuml-service

# Test connectivity from Hermes pod
kubectl exec -it -n ai-tools deployment/hermes -- curl -v http://plantuml-service:80
```

### Ingress Not Working
```bash
# Check ingress controller
kubectl get ingressclass

# Check ingress
kubectl get ingress -n ai-tools
kubectl describe ingress -n ai-tools plantuml-ingress
```

## Security Considerations

1. **Internal Access Only**: The ClusterIP service is only accessible within the cluster
2. **Ingress Security**: If using ingress, consider:
   - Adding authentication
   - Using HTTPS/TLS
   - Restricting access via network policies
3. **Resource Limits**: PlantUML can be resource-intensive for complex diagrams

## Scaling

For high-volume usage:
```yaml
# In deployment.yaml
spec:
  replicas: 2  # or more
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

## References

- [PlantUML Official Image](https://hub.docker.com/r/plantuml/plantuml-server)
- [PlantUML Documentation](https://plantuml.com/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
