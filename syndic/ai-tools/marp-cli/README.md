# Marp CLI Server for AI-Tools Namespace

This deployment provides a Marp server for converting Markdown to presentations, slides, and PDFs that can be used by Hermes Agent and other tools in the `ai-tools` namespace.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ai-tools namespace                      │
│                                                              │
│  ┌─────────────┐         ┌─────────────┐                  │
│  │   Hermes    │────────►│    Marp     │                  │
│  │   Agent     │         │  Server     │                  │
│  │             │◄────────┤             │                  │
│  └─────────────┘         └─────────────┘                  │
│       │                                             │        │
│       │                     ┌───────────────────────┤        │
│       ▼                     ▼                           ▼        │
│  ┌─────────────────────────────────────────────────────┐  │
│  │               Kubernetes ClusterIP Network           │  │
│  │     marp-service.ai-tools.svc.cluster.local:80      │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

Hermes Agent can access Marp via:
- **Internal DNS**: `http://marp-service.ai-tools.svc.cluster.local:80`
- **Ingress**: `http://marp.ai-tools.svc.cluster.local` (if ingress is configured)

## Files

| File | Purpose |
|------|---------|
| `deployment.yaml` | Marp server deployment |
| `service.yaml` | ClusterIP service for internal access |
| `ingress.yaml` | Ingress for external/internal DNS access |
| `kustomization.yaml` | Kustomize configuration for easy deployment |

## Deployment

### Option 1: Deploy with Kustomize (Recommended)

```bash
kubectl apply -k /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/marp-cli/
```

### Option 2: Deploy Individual Files

```bash
kubectl apply -f /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/marp-cli/deployment.yaml
kubectl apply -f /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/marp-cli/service.yaml
kubectl apply -f /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/ai-tools/marp-cli/ingress.yaml
```

## Configuration for Hermes Agent

### Do NOT register this as an MCP server

Neither this HTTP wrapper nor `marp-cli` itself speaks the MCP protocol. `hermes mcp add marp --url http://marp-service...` fails the same way `plantuml` does (`text/html` response, not a valid MCP handshake) — confirmed 2026-07-26. `marp-cli` is a one-shot CLI, not a persistent MCP stdio server either, so `hermes mcp add --command npx --args -y @marp-team/marp-cli` isn't valid for it.

### Direct call (confirmed working) — bypasses this Deployment entirely

Hermes bundles its own Node runtime and runs `marp-cli` directly, independent of the `marp-service` pod:

```bash
export PATH=/root/.hermes/node/bin:$PATH
npx --yes @marp-team/marp-cli /tmp/slides.md -o /tmp/slides.html
```

HTML output works out of the box; PDF/PPTX require Chrome/Chromium/Firefox, which is NOT installed in the Hermes pod (confirmed 2026-07-26 — `CLIError: No suitable browser found`).

This is documented as a persistent Hermes skill at `/root/.hermes/skills/project-mgmt/marp/SKILL.md` (on the PVC, survives pod restarts). The `marp-service` Deployment described above stays useful for other consumers (direct team/browser access, future n8n workflows) — Hermes itself just doesn't need it. See also the `infra-architecture-diagram` skill for how this fits alongside `plantuml` and the bundled `architecture-diagram` skill.

### Usage Examples from Hermes

```
# Convert Markdown to slides
marp Convert this markdown to a presentation:
---
marp: true
theme: default
---

# Slide 1

## Introduction

This is my presentation

---

# Slide 2

## Key Features

- Feature 1
- Feature 2
- Feature 3

---

# Slide 3

## Conclusion

Thank you!

# Save the presentation
save as presentation.html

# Generate PDF
marp Convert this to PDF and save as presentation.pdf
```

## Marp Server Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check - returns server status |
| `/api/marp` | POST | Convert Markdown to HTML slides |

### Example API Call

```bash
# Direct API call to convert Markdown to HTML
curl -X POST http://marp-service.ai-tools.svc.cluster.local/api/marp \
  -H "Content-Type: text/plain" \
  -d "---
marp: true
---
# Hello World
This is a slide"

# Save to file
curl -X POST http://marp-service.ai-tools.svc.cluster.local/api/marp \
  -H "Content-Type: text/plain" \
  -d "---
marp: true
---
# Hello World
This is a slide" \
  --output presentation.html
```

## Markdown Syntax for Marp

### Basic Slides

```markdown
---
marp: true
theme: default
---

# Slide Title

Content here

---

# Another Slide

More content
```

### Themes

```markdown
---
marp: true
theme: gaia
---
```

Available themes: `default`, `gaia`, `play`, `uncover`, `default`

### Speaker Notes

```markdown
---
marp: true
---

# Slide

Content

---

<!-- This is a speaker note -->

This appears only in presenter mode
```

### Fragments (Builds)

```markdown
---
marp: true
---

# Fragment Example

- Item 1
- <!-- .element: class="fragment" --> Item 2 (appears on click)
- <!-- .element: class="fragment" --> Item 3 (appears on click)
```

### Code Blocks

```markdown
---
marp: true
---

# Code Example

```python
def hello():
    print("Hello, Marp!")
```
```

### Images

```markdown
---
marp: true
---

# Image Example

![Alt text](image.png)
```

## Customization

### Change the Image

Edit `deployment.yaml` and change the image:
```yaml
image: marpteam/marp-server:latest  # Default
# or specify a version
image: marpteam/marp-server:v2.2.0
```

### Resource Limits

Adjust CPU/memory in `deployment.yaml` based on your workload:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Environment Variables

The deployment supports these environment variables:

```yaml
env:
- name: NODE_ENV
  value: "production"
- name: PORT
  value: "3000"
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
kubectl get pods -n ai-tools -l app=marp-server
kubectl get svc -n ai-tools -l app=marp-server
kubectl get ingress -n ai-tools -l app=marp-server
```

### Test the Service
```bash
# From within the cluster (using kubectl exec)
kubectl exec -it -n ai-tools deployment/hermes -- curl -X POST \
  http://marp-service:80/api/marp \
  -H "Content-Type: text/markdown" \
  -d "---
marp: true
---
# Test
This is a test slide" \
  --output /tmp/test.html

# Or via port-forward for local testing
kubectl port-forward -n ai-tools svc/marp-service 8080:80
# Then open http://localhost:8080 in your browser
```

### Test from Hermes
```bash
kubectl exec -it -n ai-tools deployment/hermes -- \
  /usr/local/lib/hermes-agent/venv/bin/hermes -z "Create a Marp presentation with 3 slides about Kubernetes"
```

## Troubleshooting

### Image Pull Errors
If you get `ImagePullBackOff`:
```bash
# Check the image exists
kubectl get pods -n ai-tools -l app=marp-server
kubectl describe pod -n ai-tools <marp-pod-name>

# Try a different image tag
kubectl set image -n ai-tools deployment/marp-server marp=marpteam/marp-server:v2.2.0
```

### Service Not Reachable
```bash
# Check service endpoint
kubectl get endpoints -n ai-tools marp-service

# Test connectivity from Hermes pod
kubectl exec -it -n ai-tools deployment/hermes -- curl -v http://marp-service:80
```

### Ingress Not Working
```bash
# Check ingress controller
kubectl get ingressclass

# Check ingress
kubectl get ingress -n ai-tools
kubectl describe ingress -n ai-tools marp-ingress
```

### Common Issues

**Issue: PDF generation not working**
- Solution: Marp server may need additional dependencies for PDF. Consider using Chrome/Chromium in the container or use the HTML output instead.

**Issue: Theme not found**
- Solution: Check theme name spelling. Use `default`, `gaia`, or `play` which are built-in.

**Issue: Markdown not rendering correctly**
- Solution: Ensure `marp: true` is in the front-matter of your Markdown.

## Security Considerations

1. **Internal Access Only**: The ClusterIP service is only accessible within the cluster
2. **Ingress Security**: If using ingress, consider:
   - Adding authentication
   - Using HTTPS/TLS
   - Restricting access via network policies
3. **Resource Limits**: Marp can be resource-intensive for large presentations with many slides
4. **Content**: Be aware that content sent to Marp may contain sensitive information

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

## Advanced Configuration

### Custom CSS

You can provide custom CSS to Marp by mounting a ConfigMap:

```yaml
# In deployment.yaml
volumes:
- name: custom-css
  configMap:
    name: marp-custom-css
```

Then reference it in your Markdown:
```markdown
---
marp: true
theme: default
style: |
  section {
    background: #f8f8f8;
  }
---
```

### Plugins

Marp supports plugins. To add plugins, you may need to build a custom Docker image.

## References

- [Marp Official Documentation](https://marp.app/)
- [Marp CLI GitHub](https://github.com/marp-team/marp-cli)
- [Marp Server Docker Image](https://hub.docker.com/r/marpteam/marp-server)
- [Marp Syntax Reference](https://marpit.marp.app/markdown)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
