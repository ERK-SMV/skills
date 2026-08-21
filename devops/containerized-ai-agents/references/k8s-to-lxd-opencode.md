# Hybrid Infrastructure: K8s Pod to LXD Container Patterns

**Session**: 2026-07-27 - Hermes in RKE2 pod connecting to OpenCode in LXD container

## Discovery

User's environment:
- Hermes running in **Kubernetes pod** (RKE2 cluster on OVH)
- OpenCode sessions booting from **LXD container**
- Need to connect these two environments

## Key Findings

### 1. Hermes Pod Environment
```bash
# Hermes bundles its own Node.js
/usr/local/lib/hermes-agent/venv/bin/hermes
/root/.hermes/node/bin/node  # v22.23.1
/root/.hermes/node/bin/npm   # 10.9.8

# Node.js path must be explicitly added to PATH
export PATH="/root/.hermes/node/bin:$PATH"
```

### 2. OpenCode Installation in Pod
```bash
# Works directly in the pod
export PATH="/root/.hermes/node/bin:$PATH"
npm install -g opencode-ai@latest
opencode --version  # 1.18.7
```

### 3. Connection Patterns

#### Pattern A: Direct SSH (Simplest)
```bash
# From Hermes pod to LXD container
terminal(command="ssh user@<lxd-ip> 'export PATH=\"/root/.hermes/node/bin:$PATH\" && opencode run \"task\"'"", pty=true)
```

#### Pattern B: Via K8s Node
```bash
# 1. Find node with LXD
kubectl get nodes -o wide

# 2. Port forward from pod to node
kubectl port-forward <node-pod> 2222:22

# 3. SSH through forwarded port
terminal(command="ssh -p 2222 user@localhost 'opencode run \"task\"'"", pty=true)
```

#### Pattern C: Direct in Pod (No LXD needed)
```bash
# Install and use OpenCode directly in Hermes pod
export PATH="/root/.hermes/node/bin:$PATH"
npm install -g opencode-ai@latest
opencode auth login
opencode run "Your task"
```

## Pitfalls Discovered

1. **Node.js path not in default PATH**
   - Hermes bundles Node.js at `/root/.hermes/node/bin/`
   - Must explicitly export: `export PATH="/root/.hermes/node/bin:$PATH"`
   - Affects both `npm` and `node` commands

2. **OpenCode not pre-installed**
   - Needs manual installation in each environment
   - `npm install -g opencode-ai@latest`

3. **K8s pod has no kubectl by default**
   - Need to install or use in-cluster config
   - Service account token available at `/run/secrets/kubernetes.io/serviceaccount/token`

4. **LXD not available in pod**
   - LXD is on the host nodes, not in containers
   - Must SSH to node first, then use `lxc` commands

## Recommended Approach

For user's specific setup (Hermes in RKE2 pod, OpenCode in LXD):

**Option 1: Install OpenCode directly in Hermes pod** (Simplest)
- No cross-environment complexity
- Full access to pod's network and files
- No SSH configuration needed

**Option 2: SSH from pod to LXD container** (If LXD has special setup)
- Requires SSH key configuration
- Requires network connectivity between pod and LXD network
- More complex but maintains existing LXD workflow

**Option 3: Port forwarding through node** (If direct SSH blocked)
- Use `kubectl port-forward` to expose node SSH
- Then SSH to localhost with forwarded port

## Verification Commands

```bash
# Check Node.js
/root/.hermes/node/bin/node --version

# Check npm
/root/.hermes/node/bin/npm --version

# Check OpenCode after install
/root/.hermes/node/bin/npx opencode --version

# Check network to LXD
ping <lxd-container-ip>
nc -zv <lxd-container-ip> 22
```

## Environment Variables

```bash
# In Hermes pod
export PATH="/root/.hermes/node/bin:$PATH"
export OPENROUTER_API_KEY="$OPENROUTER_API_KEY"
```

## Filesystem Notes

- Hermes pod has persistent storage at `/root/.hermes/`
- OpenCode config stored at `~/.opencode/`
- For shared files, consider NFS or hostPath mounts
