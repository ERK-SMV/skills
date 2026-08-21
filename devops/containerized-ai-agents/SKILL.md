---
name: containerized-ai-agents
description: Run AI agents in LXD, Docker, Kubernetes with connectivity.
version: 1.0.0
tags:
  - containers
  - lxd
  - docker
  - kubernetes
  - opencode
  - hybrid-infrastructure
---

# Containerized AI Agents

**Use when** running AI coding agents (OpenCode, Claude Code, Codex) in containerized environments and need cross-environment connectivity.

## Overview

Patterns for running AI coding agents in LXD, Docker, and Kubernetes pods with connectivity between environments. Special focus on RKE2 clusters and hybrid infrastructure (K8s + LXD).

## When to Use

- OpenCode/Claude Code/Codex in LXD containers
- Connecting from Kubernetes pods to containerized agents
- Hybrid infrastructure: K8s + LXD
- Isolating AI agents from sensitive host files

## Prerequisites

- LXD/Docker/Kubernetes as appropriate
- Node.js/npm in containers
- SSH access between environments

---

## LXD Container Patterns

### Basic Setup

```bash
# Install LXD
sudo snap install lxd
sudo lxd init
sudo usermod -aG lxd $USER
newgrp lxd

# Create container with bind mount
lxc launch debian:bookworm opencode-env
lxc config device add opencode-env dev-dir disk \
  source=/home/$USER/dev path=/home/ubuntu/dev

# Install OpenCode
lxc exec opencode-env -- bash -c "apt update && apt install -y curl && curl -fsSL https://opencode.ai/install | bash"

# Run
lxc exec opencode-env -- su - ubuntu -c "opencode"
```

**Alias for convenience:**
```bash
alias opencode="lxc exec opencode-env -- su - ubuntu -c opencode"
```

---

## Kubernetes Patterns

### Running OpenCode in Pods (RKE2)

```bash
export PATH="/root/.hermes/node/bin:$PATH"
npm install -g opencode-ai@latest
opencode --version
```

### Connecting K8s to LXD

**Option 1: SSH Forwarding**
```bash
# From Hermes pod
terminal(command="ssh user@<lxd-ip> 'opencode run \"task\"'"", pty=true)
```

**Option 2: Port Forwarding**
```bash
kubectl port-forward <node-pod> 2222:22
terminal(command="ssh -p 2222 user@localhost 'opencode run \"task\"'"", pty=true)
```

---

## Docker Patterns

```bash
docker run -it --rm \
  -v /home/$USER/dev:/home/user/dev \
  -v /home/$USER/.ssh:/home/user/.ssh:ro \
  -e OPENROUTER_API_KEY=$OPENROUTER_API_KEY \
  ghcr.io/sudo-tee/opencode:latest \
  opencode
```

---

## Hybrid Workflows

### Hermes in K8s, OpenCode in LXD

```bash
# On RKE2 node with LXD
lxc launch debian:bookworm opencode-env
lxc config device add opencode-env dev-dir disk source=/home/$USER/dev path=/home/ubuntu/dev
lxc exec opencode-env -- bash -c "curl -fsSL https://opencode.ai/install | bash"

# In Hermes pod
terminal(command="ssh node-user@<node-ip> 'lxc exec opencode-env -- su - ubuntu -c \"opencode run \\\"task\\\"\"'"", pty=true)
```

---

## Connectivity

### SSH Setup

```bash
ssh-keygen -t ed25519 -f ~/.ssh/opencode_key
ssh-copy-id -i ~/.ssh/opencode_key.pub user@<k8s-node-ip>
ssh-copy-id -i ~/.ssh/opencode_key.pub user@<lxd-ip>
```

### Network Checks

```bash
# From K8s to LXD
kubectl exec -it hermes-pod -- ping <lxd-ip>
kubectl exec -it hermes-pod -- nc -zv <lxd-ip> 22

# From LXD to K8s
lxc exec opencode-env -- curl -v http://<k8s-service-ip>:<port>
```

---

## Authentication

### API Keys in LXD

```bash
lxc config set opencode-env environment.OPENROUTER_API_KEY "sk-..."
```

### Kubernetes Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: opencode-secrets
stringData:
  OPENROUTER_API_KEY: "sk-..."
```

---

## Debugging

| Issue | Solution |
|-------|----------|
| Node.js not found | Install in container: `apt install -y nodejs` |
| Files not syncing | Verify bind mount: `lxc config device list name` |
| SSH refused | Check connectivity: `ping <ip>`, `nc -zv <ip> 22` |
| Permission denied | Fix host permissions: `chmod -R a+rwX /path` |

---

## Verification

```bash
# Test LXD
echo "test" > /home/$USER/dev/test.txt
lxc exec opencode-env -- cat /home/ubuntu/dev/test.txt

# Test K8s to LXD
kubectl exec -it hermes-pod -- ssh user@<lxd-ip> "opencode --version"
```

---

## Quick Reference

| Task | LXD | Docker | Kubernetes |
|------|-----|--------|------------|
| Create | `lxc launch img name` | `docker create img` | `kubectl create -f pod.yaml` |
| Exec | `lxc exec name -- cmd` | `docker exec name cmd` | `kubectl exec pod -- cmd` |
| Mount | `lxc config device add` | `-v /host:/cont` | `volumes` |
| IP | `lxc list -c n` | `docker inspect -f '{{.IP}}'` | `kubectl get pod -o wide` |

---

## Related Skills

- `opencode` - OpenCode CLI usage
- `infra-k8s-manager` - RKE2 infrastructure
- `ai-toolset` - DevOps automation