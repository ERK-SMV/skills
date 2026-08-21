# Odoo MCP Server Integration with Hermes Agent

**Complete setup guide for connecting Odoo to your Hermes AI assistant via MCP**

This guide explains how to deploy the **Odoo MCP Server module** in your Odoo instances and connect it to your **Hermes Agent** (central AI orchestrator in Kubernetes).

---

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                    YOUR EXISTING INFRASTRUCTURE                     │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    KUBERNETES CLUSTER                       │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              HERMES AGENT (Central)                    │  │  │
│  │  │  • Orchestrator                                        │  │  │
│  │  │  • Long-term memory                                     │  │  │
│  │  │  • MCP Client (connects to Odoo MCP Server)             │  │  │
│  │  │  • Runs in: pre-prod namespace                          │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────────────────┐    ┌─────────────────────┐    │  │
│  │  │   Odoo 14/16/18     │    │   Other MCP Servers │    │  │
│  │  │   (FNFE/ERK)        │    │   (GitLab, PG, K8s)   │    │  │
│  │  │                     │    │                     │    │  │
│  │  │  ┌───────────────┐  │    │                     │    │  │
│  │  │  │ MCP Server    │◄─┼────►  HERMES MCP Client    │    │  │
│  │  │  │ Module        │  │    │  (mcp-server-odoo)    │    │  │
│  │  │  └───────────────┘  │    │                     │    │  │
│  │  └─────────────────────┘    └─────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Local Machine / LXD Container                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  OPENCODE (Optional)                                    │    │
│  │  • Local execution                                     │    │
│  │  • Connects to Hermes via K8s API                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 **Components**

| Component | Location | Purpose |
|-----------|----------|---------|
| **mcp_server** | `mcp_server-19.0.1.0.0/mcp_server/` | Odoo module - installs in Odoo instances |
| **mcp-client** | `mcp_server-19.0.1.0.0/mcp-client/` | Python MCP client from GitHub |
| **Hermes** | Kubernetes (pre-prod namespace) | Central AI assistant |

---

## ✅ **Prerequisites**

Your existing infrastructure already provides:
- ✅ **Odoo instances** (14.0, 16.0, 18.0 in FNFE/ERK)
- ✅ **Kubernetes cluster** (RKE2 on OVH)
- ✅ **Hermes deployment** (from ai-toolset skill)
- ✅ **PostgreSQL** (for Odoo databases)
- ✅ **Ingress** (NGINX with cert-manager)

---

## 🎯 **Step 1: Install Odoo MCP Server Module**

### For Each Odoo Instance (14.0, 16.0, 18.0)

#### 1.1 Copy Module to Addons

```bash
# For Odoo 14 (FNFE)
cp -r /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/mcp_server-19.0.1.0.0/mcp_server \
   /path/to/odoo-14-addons/

# For Odoo 16
cp -r /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/mcp_server-19.0.1.0.0/mcp_server \
   /path/to/odoo-16-addons/

# For Odoo 18 (ERK)
cp -r /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/mcp_server-19.0.1.0.0/mcp_server \
   /path/to/odoo-18-addons/
```

#### 1.2 Update Module List & Install

```bash
# In Odoo web interface:
# 1. Go to: Apps
# 2. Click: Update Apps List
# 3. Search: "MCP Server"
# 4. Click: Install

# OR via command line:
odoo -d your_database --update=all --init=mcp_server --stop-after-init
```

#### 1.3 Configure Security Groups

```bash
# In Odoo:
# 1. Go to: Settings > Users & Companies > Groups
# 2. Find: "MCP Administrator" and "MCP User"
# 3. Assign users to appropriate groups
```

#### 1.4 Enable Models for MCP Access

```bash
# In Odoo:
# 1. Go to: Settings > MCP Server > Enabled Models
# 2. Add models you want to expose to Hermes:
#    - res.partner (customers/suppliers)
#    - product.product (products)
#    - sale.order (sales)
#    - account.invoice (invoices)
#    - project.task (tasks)
#    - etc.
# 3. Set permissions for each model:
#    - Can Read: ✅
#    - Can Write: ✅ (if needed)
#    - Can Create: ✅ (if needed)
#    - Can Delete: ❌ (usually not needed)
```

#### 1.5 Generate API Keys

```bash
# In Odoo:
# 1. Go to: Settings > Users & Companies > Users
# 2. Select a user with MCP permissions
# 3. Navigate to: API Keys tab
# 4. Click: New API Key
# 5. Provide description: "Hermes MCP Access"
# 6. Copy the key (it won't be shown again!)
# 7. Store in Passbolt: pass insert odoo/mcp-api-key
```

---

## 🎯 **Step 2: Deploy MCP Client to Kubernetes**

The `mcp-server-odoo` Python package needs to run in your Kubernetes cluster to connect your Odoo instances to Hermes.

### 2.1 Create Kubernetes Deployment

Create `mcp_server-19.0.1.0.0/k8s/mcp-odoo-client.yaml`:

```yaml
---
# Namespace: Use existing pre-prod or create new
apiVersion: v1
kind: Namespace
metadata:
  name: mcp

---
# Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mcp-odoo
  namespace: mcp

---
# ConfigMap for configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: mcp-odoo-config
  namespace: mcp
data:
  # Configuration for each Odoo instance
  config.json: |
    {
      "odoo_instances": {
        "odoo-14-fnfe": {
          "url": "https://fnfe.test.flows.cab",
          "api_key_env": "ODOO_14_API_KEY",
          "db": "fnfe14"
        },
        "odoo-18-erk": {
          "url": "https://erk.flows.cab",
          "api_key_env": "ODOO_18_API_KEY",
          "db": "erk18"
        }
      }
    }

---
# Secrets (store API keys from Passbolt)
apiVersion: v1
kind: Secret
metadata:
  name: mcp-odoo-secrets
  namespace: mcp
type: Opaque
stringData:
  ODOO_14_API_KEY: "REPLACE_WITH_PASSBOLT_VALUE"
  ODOO_16_API_KEY: "REPLACE_WITH_PASSBOLT_VALUE"
  ODOO_18_API_KEY: "REPLACE_WITH_PASSBOLT_VALUE"

---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-odoo-client
  namespace: mcp
  labels:
    app: mcp-odoo-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mcp-odoo-client
  template:
    metadata:
      labels:
        app: mcp-odoo-client
    spec:
      serviceAccountName: mcp-odoo
      containers:
      - name: mcp-odoo
        image: python:3.11-slim
        command: ["uvx"]
        args: ["--directory", "/app/mcp-server-odoo", "mcp_server_odoo"]
        env:
        # Odoo 14
        - name: ODOO_14_URL
          value: "https://fnfe.test.flows.cab"
        - name: ODOO_14_API_KEY
          valueFrom:
            secretKeyRef:
              name: mcp-odoo-secrets
              key: ODOO_14_API_KEY
        - name: ODOO_14_DB
          value: "fnfe14"
        
        # Odoo 18
        - name: ODOO_18_URL
          value: "https://erk.flows.cab"
        - name: ODOO_18_API_KEY
          valueFrom:
            secretKeyRef:
              name: mcp-odoo-secrets
              key: ODOO_18_API_KEY
        - name: ODOO_18_DB
          value: "erk18"
        
        # MCP Server Configuration
        - name: MCP_TRANSPORT
          value: "stdio"
        - name: MCP_LOG_LEVEL
          value: "INFO"
        
        ports:
        - containerPort: 8000
          name: mcp
        
        volumeMounts:
        - name: mcp-client
          mountPath: /app/mcp-server-odoo
        - name: config
          mountPath: /app/config
          readOnly: true
        
      volumes:
      - name: mcp-client
        emptyDir: {}
      - name: config
        configMap:
          name: mcp-odoo-config
```

### 2.2 Build Custom Docker Image (Recommended)

Create `mcp_server-19.0.1.0.0/k8s/Dockerfile`:

```dockerfile
FROM python:3.11-slim

# Install UV (required by mcp-server-odoo)
RUN pip install uv

# Install mcp-server-odoo from local source
WORKDIR /app
COPY mcp-client /app/mcp-server-odoo
RUN cd /app/mcp-server-odoo && pip install -e .

# Install additional dependencies
RUN pip install mcp httpx

# Set entrypoint
ENTRYPOINT ["uvx"]
CMD ["--directory", "/app/mcp-server-odoo", "mcp_server_odoo"]
```

Build and push:

```bash
cd /home/erk-smv/Documents/2.PRO_KSuite_29MAY2026/CODING/ERK-CODING/2.erk-infra/app/second-brain/odoo-opensource-developper/mcp_server-19.0.1.0.0

docker build -t registry.gitlab.akretion.com/akretion/mcp/mcp-odoo-client:latest -f k8s/Dockerfile .
docker push registry.gitlab.akretion.com/akretion/mcp/mcp-odoo-client:latest
```

Update the deployment to use your custom image:

```yaml
# In mcp-odoo-client.yaml
containers:
- name: mcp-odoo
  image: registry.gitlab.akretion.com/akretion/mcp/mcp-odoo-client:latest
  command: ["mcp-server-odoo"]
  args: ["--transport", "stdio"]
```

---

## 🎯 **Step 3: Configure Hermes to Use MCP Server**

Your Hermes is already deployed in Kubernetes. You need to configure it to connect to the Odoo MCP server.

### 3.1 Update Hermes Configuration

Edit your Hermes configuration (`~/.hermes/config.json` or ConfigMap in Kubernetes):

```json
{
  "mcpServers": {
    "odoo-14-fnfe": {
      "url": "http://mcp-odoo-client.mcp.svc.cluster.local:8000",
      "transport": "stdio"
    },
    "odoo-18-erk": {
      "url": "http://mcp-odoo-client.mcp.svc.cluster.local:8000",
      "transport": "stdio"
    },
    "gitlab": {
      "command": "mcp-server-gitlab",
      "args": ["--token", "$GITLAB_TOKEN", "--baseUrl", "https://gitlab.com"]
    },
    "postgres": {
      "command": "mcp-server-postgres",
      "args": ["--connectionString", "$ODOO_DB_URL"]
    },
    "kubernetes": {
      "command": "mcp-server-kubernetes",
      "args": ["--kubeconfig", "/home/user/.kube/config"]
    }
  },
  "model": {
    "provider": "mistral",
    "apiKey": "$MISTRAL_API_KEY"
  }
}
```

### 3.2 Deploy Updated Hermes Configuration

```bash
# Update the ConfigMap
kubectl create configmap hermes-config -n pre-prod \
  --from-file=config.json \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart Hermes
kubectl rollout restart deployment/hermes -n pre-prod
```

---

## 🎯 **Step 4: Alternative - Direct Connection from OpenCode**

If you want to connect directly from **OpenCode** (in LXD container) to Odoo:

### 4.1 Configure OpenCode MCP Servers

Edit OpenCode configuration (`~/.opencode/opencode.jsonc`):

```json
{
  "mcp": {
    "odoo": {
      "command": "uvx",
      "args": ["--directory", "/app/mcp-server-odoo", "mcp_server_odoo"],
      "env": {
        "ODOO_URL": "https://erk.flows.cab",
        "ODOO_API_KEY": "your-api-key-from-passbolt",
        "ODOO_DB": "erk18"
      }
    }
  }
}
```

### 4.2 Run OpenCode with Odoo MCP

```bash
# In your LXD container
cd /app/mcp-server-odoo
uv pip install -e .
opencode
```

---

## 🔐 **Security Configuration**

### 5.1 API Key Rotation

```bash
# In Odoo:
# 1. Go to user's API Keys tab
# 2. Click "Regenerate" on existing key
# 3. Update Kubernetes secret:
kubectl create secret generic mcp-odoo-secrets -n mcp \
  --from-literal=ODOO_18_API_KEY=$(pass show odoo/mcp-api-key) \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 5.2 Model Access Control

**Principle of Least Privilege:**
- Only enable models that Hermes needs to access
- Disable write/create/delete for most models
- Use read-only access where possible

```python
# In Odoo MCP Server settings, for each model:
{
    "res.partner": {"read": true, "write": false, "create": false, "delete": false},
    "product.product": {"read": true, "write": false, "create": false, "delete": false},
    "sale.order": {"read": true, "write": true, "create": false, "delete": false},
}
```

### 5.3 Network Security

- **HTTPS only**: Ensure Odoo instances use HTTPS
- **Firewall rules**: Restrict MCP server access to Hermes only
- **Rate limiting**: Configure in Odoo MCP Server settings
- **Audit logging**: All MCP operations are logged in Odoo

---

## 📊 **Testing the Connection**

### 6.1 Test Odoo MCP Endpoints

```bash
# Health check
curl https://erk.flows.cab/mcp/health

# Validate API key
curl -X POST https://erk.flows.cab/mcp/auth/validate \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json"

# List enabled models
curl https://erk.flows.cab/mcp/models \
  -H "X-API-Key: your-api-key"
```

### 6.2 Test Hermes Connection

```bash
# Ask Hermes to query Odoo
hermes ask "List the first 10 customers from Odoo"

# Check if Hermes can see the MCP server
hermes list-mcp
```

### 6.3 Example Queries

Once connected, you can ask Hermes:

```bash
# List customers
"Show me all customers from France"

# Search products
"Find all products with 'Odoo' in the name"

# Get sales data
"What were the top 5 sales orders by amount last month?"

# Create a customer
"Create a new customer named 'Acme Corp' with email 'contact@acme.com'"

# Update a product
"Update the price of product 'Odoo Subscription' to 1500"
```

---

## 📝 **Maintenance & Troubleshooting**

### 7.1 Common Issues

| Issue | Solution |
|-------|----------|
| **Connection refused** | Check if Odoo MCP Server module is installed |
| **API key not working** | Verify key in Odoo user settings, check MCP User group |
| **Model not found** | Enable model in MCP Server > Enabled Models |
| **Permission denied** | Check model permissions and user group membership |
| **Hermes can't connect** | Verify MCP client is running, check network connectivity |
| **Rate limited** | Increase rate limit in MCP Server settings |

### 7.2 Debug Commands

```bash
# Check MCP client logs
kubectl logs -f deployment/mcp-odoo-client -n mcp

# Check Hermes logs
kubectl logs -f deployment/hermes -n pre-prod

# Test MCP server directly
kubectl exec -it deployment/mcp-odoo-client -n mcp -- bash
curl -X POST http://localhost:8000/mcp/tools/list \
  -H "Content-Type: application/json"
```

### 7.3 Monitor Usage

```bash
# Check Odoo MCP Server logs
# In Odoo: Settings > Technical > Logs
# Filter by: MCP

# Check API usage
# In Odoo: Settings > MCP Server > API Usage Statistics
```

---

## 📚 **References**

| Resource | Description |
|----------|-------------|
| [Odoo MCP Server Module](https://github.com/ivnvxd/mcp-server-odoo) | Python MCP client |
| [MCP Protocol](https://modelcontextprotocol.io/) | Official MCP documentation |
| [Hermes Documentation](https://github.com/NousResearch/Hermes) | Hermes setup and configuration |
| [Your Hermes Config](~/.hermes/config.json) | Current Hermes configuration |

---

## 🚀 **Quick Start**

```bash
# 1. Install Odoo MCP Server module
cp -r mcp_server /odoo/addons/
# In Odoo: Install MCP Server module

# 2. Create API key
# In Odoo: Settings > Users > API Keys > New

# 3. Deploy MCP client to Kubernetes
kubectl apply -f mcp_server-19.0.1.0.0/k8s/mcp-odoo-client.yaml

# 4. Update Hermes configuration
kubectl apply -f hermes-config.yaml
kubectl rollout restart deployment/hermes -n pre-prod

# 5. Test connection
hermes ask "List customers from Odoo"
```

---

## 💡 **Best Practices**

1. **Start with read-only access** for all models
2. **Enable write/create gradually** as needed
3. **Use dedicated API users** (not admin accounts)
4. **Rotate API keys** regularly (every 90 days)
5. **Monitor API usage** for suspicious activity
6. **Enable audit logging** in Odoo MCP Server
7. **Test in staging first** before production
8. **Document enabled models** and their purposes

---

*This guide integrates the Odoo MCP Server with your existing Hermes/Kubernetes infrastructure.*
