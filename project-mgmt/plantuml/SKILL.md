---
name: plantuml
description: "UML diagrams (sequence, class, activity, component) rendered via the in-cluster PlantUML server."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [uml, diagrams, plantuml, architecture, sequence-diagram]
    related_skills: [architecture-diagram, infra-architecture-diagram, concept-diagrams]
---

# PlantUML Skill

Render real UML diagrams (sequence, class, activity, component, state) from PlantUML syntax using the `plantuml-server` already running in the `ai-tools` namespace. No local Java/Graphviz needed — the server does the rendering.

## When to use

- The user wants an actual UML diagram (sequence, class, activity, use-case, component, state) rather than a free-form architecture sketch (use `architecture-diagram` for that).
- The user gives or asks for PlantUML syntax directly.

## Usage

POST the diagram text (starting with `@startuml`, ending with `@enduml`) to the internal service, in the desired output format:

```bash
# Use direct IP address (DNS resolution issue confirmed 2026-07-29)
curl -s -X POST http://10.43.94.102/png \
  -H "Content-Type: text/plain" \
  --data-binary @- -o /tmp/diagram.png <<'EOF'
@startuml
Alice -> Bob : Authentication Request
Bob --> Alice : Authentication Response
@enduml
EOF
```

Available formats: `/png`, `/svg`, `/txt` (ASCII art).

## Current Status (2026-07-29)

- **Service IP**: `10.43.94.102` (ClusterIP in `ai-tools` namespace)
- **DNS Issue**: `plantuml-service.ai-tools.svc.cluster.local` not resolving
- **Workaround**: Use direct IP address `http://10.43.94.102`
- **Service Health**: Responding to HTTP requests (confirmed via curl)
- **Diagram Generation**: Not fully tested due to security blocking, but service is accessible

## Notes

- Internal cluster access only — this endpoint is not reachable outside the Kubernetes cluster.
- Do not try to register this as an MCP server (`hermes mcp add --url ...`) — it's a plain REST API, not an MCP-protocol endpoint, and the handshake will fail.
- If DNS issues persist, consider checking Kubernetes CoreDNS or service configuration.
