---
name: ai-toolset
version: 1.0.0
description: DevOps automation via Hermes, OpenCode, and MCP servers.
author: Sebastien Maurines
maintainers:
  - sebastien.maurines@it-is-a-sport.com
  - team@it-is-a-sport.com
license: MIT
repository: git@gitlab.com:it-is-a-sport/skills.git
issues: https://gitlab.com/it-is-a-sport/skills/-/issues
tags:
  - devops
  - hermes
  - opencode
  - neovim
  - mistral
  - mcp
  - kubernetes
  - rancher
  - odoo
  - terraform
  - ansible
  - gitlab
  - postgres
  - infomaniak
  - production
  - team
---

# AI Toolset - IT is a Sport DevOps AI Assistant

## 🎯 **Overview**
**AI Toolset** is the **central skill** for all IT is a Sport DevOps operations, providing a unified interface to:
- **Infrastructure**: Kubernetes (Rancher), Terraform, Ansible
- **Applications**: Odoo (XML-RPC), custom APIs
- **Code**: GitLab repositories
- **Data**: PostgreSQL databases
- **Services**: Infomaniak (Mail, kDrive, Domains)
- **AI**: Mistral LLM for reasoning and automation
- **Workflow**: N8n for automation and resilience

**Architecture**: All team members connect to **ONE shared Hermes server** that orchestrates all MCP servers.

## 📋 **Prerequisites**

### **Required Tools**
 | Tool | Version | Installation |
 |------|---------|--------------|
 | Hermes | ≥1.0.0 | Kubernetes Deployment (single instance for team) |
 | OpenCode | ≥0.1.0 | Local + NeoVim plugin (each developer) |
 | NeoVim | ≥0.9.0 | System package |
 | kubectl | ≥1.25.0 | System package |
 | GitLab CLI | ≥1.0.0 | Optional |
 | Mistral API | - | API key configured |
 | N8n | ≥1.0.0 | Kubernetes Deployment (optional for workflows) |
 | PlantUML | ≥1.2023.4 | Kubernetes Deployment (ai-tools namespace) |
 | Marp CLI | ≥3.0.0 | Kubernetes Deployment (ai-tools namespace) |

### **Required Access**
- [ ] Kubernetes cluster access (pre-prod and prod namespaces)
- [ ] GitLab API token with `read_api`, `read_repository`, `write_repository` scopes
- [ ] PostgreSQL read/write access (Odoo DB)
- [ ] Infomaniak API token (Mail, kDrive, Domains)
- [ ] Mistral API key
- [ ] Rancher access (if using Rancher UI)

---

## 📥 **OpenCode Installation (LXD Container - Recommended for Security)**

**Why LXD?** OpenCode needs broad system access. Running it directly on your host exposes SSH keys, API tokens, and sensitive files in your home directory. LXD containers provide isolation while allowing file access via bind mounts.

### Setup LXD Container with Mounted Directory
```bash
# 1. Install LXD (if not already installed)
sudo snap install lxd
sudo lxd init  # Accept defaults
sudo usermod -aG lxd $USER
newgrp lxd

# 2. Create container
lxc launch debian:bookworm opencode-env

# 3. Mount your dev directory (bind mount - NO data duplication)
lxc config device add opencode-env dev-dir disk \
  source=/home/$USER/dev path=/home/ubuntu/dev

# 4. Install OpenCode in the container
lxc exec opencode-env -- bash -c "apt update && apt install -y curl && curl -fsSL https://opencode.ai/install | bash"

# 5. Run OpenCode
lxc exec opencode-env -- su - ubuntu -c "opencode"
```

### Usage Tips
- Files in `/home/$USER/dev` on host = `/home/ubuntu/dev` in container
- Changes are immediate on both sides (same files, no copy)
- To make it easier, add this alias to your `~/.bashrc`:
  ```bash
  alias opencode="lxc exec opencode-env -- su - ubuntu -c opencode"
  ```

---

## 🚀 **Quick Start**

### **1. Clone the Repository**
```bash
git clone git@gitlab.com\:it-is-a-sport/skills.git
cd skills/ai-toolset



2. Deploy MCP Servers
bash
Copy

# Deploy all MCP servers to pre-prod namespace
kubectl apply -f setup/mcp-servers/

# Verify all MCP servers are running
kubectl get pods -n pre-prod | grep mcp

# Expected output:
# gitlab-mcp-abc123           1/1     Running   0          2m
# postgres-mcp-xyz789        1/1     Running   0          2m
# kubernetes-mcp-123abc     1/1     Running   0          2m
# infomaniak-mcp-def456     1/1     Running   0          2m
# terraform-mcp-ghi789      1/1     Running   0          2m
# ansible-mcp-jkl012        1/1     Running   0          2m



3. Configure Hermes
bash
Copy

# Copy the Hermes configuration template
cp setup/hermes-config.json ~/.hermes/config.json

# Edit with your tokens (or use environment variables)
nvim ~/.hermes/config.json

# Restart Hermes to apply changes
kubectl rollout restart deployment/hermes -n pre-prod



4. Setup NeoVim
bash
Copy

# Copy NeoVim configuration
mkdir -p ~/.config/nvim/lua/plugins
cp setup/neovim-setup.lua ~/.config/nvim/lua/plugins/ai-toolset.lua

# Install plugins (using lazy.nvim)
nvim +Lazy +sync

# Or with Packer
nvim +PackerSync



5. Setup OpenCode
bash
Copy

# Install OpenCode NeoVim plugin
git clone https://github.com/sudo-tee/opencode.nvim ~/.config/nvim/pack/plugins/start/opencode.nvim

# Configure OpenCode to connect to Hermes
cp setup/opencode-config.json ~/.opencode/opencode.jsonc



6. Load the Skill
text
Copy

 /skill ai-toolset



7. Verify Everything Works
bash
Copy

# Test Hermes
hermes test-mcp

# Test NeoVim commands
nvim +AIToolsetHealth

# Test OpenCode
opencode run "List Kubernetes pods"




🧠 Architecture
text
Copy

┌─────────────────────────────────────────────────────────────────┐
│                        TEAM MEMBERS (Multiple)                      │
│  ┌─────────────┐    ┌─────────────┐    ┌───────────────────────┐  │
│  │   NEOVIM    │    │  OPENCODE   │    │   TERMINAL             │  │
│  │  (Editor)   │◄───►│  (Local)    │◄───►│   (Local Commands)     │  │
│  └─────────────┘    └─────────────┘    └───────────────────────┘  │
└─────────────────────────┬────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────────────────────────────┐
              │                   KUBERNETES                     │
              │  ┌─────────────────────────────────────────┐  │
              │  │             HERMES (1 Pod)                │  │
              │  │  • Central orchestrator                    │  │
              │  │  • Long-term memory                        │  │
              │  │  • MCP client                              │  │
              │  │  • Mistral integration                     │  │
              │  └──────────────────┬──────────────────────┘  │
              │                     │                          │
              │        ┌────────────┴────────────┐           │
              │        │                         │           │
              │  ┌─────▼─────┐          ┌────────▼────────┐  │
              │  │ GitLab     │          │ PostgreSQL       │  │
              │  │ MCP Server │          │ MCP Server        │  │
              │  └────────────┘          └──────────────────┘  │
              │                                             │
              │  ┌─────────────────┐    ┌─────────────────┐    │
              │  │ Kubernetes       │    │ Infomaniak        │    │
              │  │ MCP Server        │    │ MCP Server        │    │
              │  └─────────────────┘    └─────────────────┘    │
              │                                             │
              │  ┌─────────────────┐    ┌─────────────────┐    │
              │  │ Terraform         │    │ N8n               │    │
              │  │ MCP Server        │    │ (Workflow Engine)│    │
              │  └─────────────────┘    └─────────────────┘    │
              └───────────────────────────────────────────────┘




🔌 MCP Servers Configuration
Centralized in Hermes (setup/hermes-config.json):
json
Copy

{
  "mcpServers": {
    "gitlab": {
      "command": "mcp-server-gitlab",
      "args": [
        "--token", "\$GITLAB_TOKEN",
        "--baseUrl", "https://gitlab.com",
        "--allowedRepos", "it-is-a-sport/*"
      ],
      "timeout": 30000,
      "retries": 3,
      "environment": {
        "GITLAB_TOKEN": "\$GITLAB_TOKEN"
      }
    },
    "postgres": {
      "command": "mcp-server-postgres",
      "args": [
        "--connectionString", "\$ODOO_DB_URL",
        "--allowedSchemas", "public,odoo",
        "--readOnly", "false"
      ],
      "environment": {
        "ODOO_DB_URL": "postgres://user\:pass@odoo-db:5432/odoo"
      }
    },
    "kubernetes": {
      "command": "mcp-server-kubernetes",
      "args": [
        "--kubeconfig", "/home/user/.kube/config",
        "--allowedNamespaces", "pre-prod,prod,odoo,ai-tools",
        "--readOnly", "false"
      ]
    },
    "infomaniak": {
      "url": "http://infomaniak-mcp.pre-prod.svc.cluster.local:3000/sse",
      "transport": "sse",
      "headers": {
        "Authorization": "Bearer \$INFOMANIAK_TOKEN"
      }
    },
    "terraform": {
      "command": "mcp-server-terraform",
      "args": [
        "--workingDir", "/workspace/terraform",
        "--allowedCommands", "plan,validate,show,output"
      ]
    },
    "ansible": {
      "command": "python3",
      "args": ["-m", "mcp_server_ansible"],
      "environment": {
        "ANSIBLE_VAULT_PASSWORD_FILE": "/vault/ansible-vault-password"
      }
    },
    "n8n": {
      "url": "http://n8n.pre-prod.svc.cluster.local:5678/webhook",
      "transport": "http"
    },
    "plantuml": {
      "url": "http://plantuml-service.ai-tools.svc.cluster.local/svg",
      "transport": "http",
      "timeout": 60000,
      "retries": 2
    },
    "marp": {
      "url": "http://marp-service.ai-tools.svc.cluster.local:80",
      "transport": "http",
      "timeout": 120000,
      "retries": 2
    }
  },
  "model": {
    "provider": "mistral",
    "apiKey": "\$MISTRAL_API_KEY",
    "defaultModel": "mistral-large-latest",
    "maxTokens": 4096,
    "temperature": 0.7,
    "topP": 0.9
  },
  "accessControl": {
    "ai-toolset": {
      "allowedGroups": ["devops", "developers", "sysadmins"],
      "deniedGroups": ["interns", "viewers"],
      "readOnly": false
    }
  },
  "audit": {
    "enabled": true,
    "logMCP": true,
    "logModel": true,
    "retentionDays": 90
  },
  "rateLimits": {
    "mcp": {
      "requestsPerMinute": 100,
      "burst": 10
    },
    "model": {
      "requestsPerMinute": 30,
      "burst": 5
    }
  },
  "features": {
    "odoo": { "enabled": true, "version": "1.0" },
    "terraform": { "enabled": true, "version": "1.0" },
    "ansible": { "enabled": true, "version": "1.0" },
    "infomaniak": { "enabled": true, "version": "1.0" },
    "gitlab": { "enabled": true, "version": "1.0" },
    "kubernetes": { "enabled": true, "version": "1.0" },
    "n8n": { "enabled": true, "version": "1.0" },
    "plantuml": { "enabled": true, "version": "1.0" },
    "marp": { "enabled": true, "version": "1.0" }
  }
}




🛠️ Available Tools
Hermes Tools (Centralized)

  
    
      Category
      Tool
      Description
      Example
    
  
  
    
      GitLab
      gitlab/list_repos
      List accessible repositories
      gitlab/list_repos
    
    
      
      gitlab/get_repo
      Get repository details
      gitlab/get_repo {repo: "it-is-a-sport/odoo-modules"}
    
    
      
      gitlab/list_mrs
      List merge requests
      gitlab/list_mrs {state: "opened"}
    
    
      
      gitlab/create_mr
      Create merge request
      gitlab/create_mr {source: "feature/x", target: "main"}
    
    
      
      gitlab/get_file
      Get file from repo
      gitlab/get_file {repo: "x", path: "y"}
    
    
      PostgreSQL
      postgres/query
      Execute SQL query
      postgres/query {query: "SELECT * FROM ir_module_module"}
    
    
      
      postgres/tables
      List tables in schema
      postgres/tables {schema: "public"}
    
    
      
      postgres/schema
      Get table schema
      postgres/schema {table: "ir_model"}
    
    
      Kubernetes
      kubernetes/get_pods
      List pods
      kubernetes/get_pods {namespace: "odoo"}
    
    
      
      kubernetes/get_logs
      Get pod logs
      kubernetes/get_logs {namespace: "odoo", pod: "odoo-abc123"}
    
    
      
      kubernetes/describe
      Describe resource
      kubernetes/describe {kind: "deployment", name: "odoo"}
    
    
      
      kubernetes/apply
      Apply manifest
      kubernetes/apply {manifest: "..."}
    
    
      Infomaniak
      infomaniak/mail/list
      List email accounts
      infomaniak/mail/list
    
    
      
      infomaniak/mail/get
      Get email details
      infomaniak/mail/get {email: "contact@it-is-a-sport.com"}
    
    
      
      infomaniak/drive/list
      List kDrive files
      infomaniak/drive/list {path: "/"}
    
    
      
      infomaniak/drive/download
      Download file
      infomaniak/drive/download {file_id: "123"}
    
    
      
      infomaniak/domain/list
      List domains
      infomaniak/domain/list
    
    
      
      infomaniak/domain/dns
      Get DNS records
      infomaniak/domain/dns {domain: "it-is-a-sport.com"}
    
    
      Terraform
      terraform/plan
      Run terraform plan
      terraform/plan {directory: "/terraform/odoo"}
    
    
      
      terraform/validate
      Validate configuration
      terraform/validate {directory: "/terraform/odoo"}
    
    
      
      terraform/show
      Show state
      terraform/show {directory: "/terraform/odoo"}
    
    
      
      terraform/output
      Get outputs
      terraform/output {directory: "/terraform/odoo"}
    
    
      Ansible
      ansible/playbook_check
      Run playbook in check mode
      ansible/playbook_check {playbook: "deploy-odoo.yml"}
     
     
       
      ansible/playbook_run
      Run playbook
      ansible/playbook_run {playbook: "deploy-odoo.yml"}
     
     
       
      ansible/inventory
      List inventory
      ansible/inventory
     
     
       
      N8n
      n8n/trigger_workflow
      Trigger N8n workflow
      n8n/trigger_workflow {workflow_id: "123", parameters: {}}
     
     
       
      n8n/list_workflows
      List available workflows
      n8n/list_workflows
     
     
       
      PlantUML
      plantuml/generate
      Generate diagram from PlantUML source
      plantuml/generate {diagram: "@startuml...@enduml", format: "svg"}
     
     
       
      plantuml/render
      Render PlantUML file
      plantuml/render {file: "/path/to/diagram.puml", format: "png"}
     
     
       
      Marp
      marp/generate
      Generate presentation from Markdown
      marp/generate {content: "# Slide 1...", format: "pdf"}
     
     
       
      marp/render
      Render Marp file to HTML/PDF/PPTX
      marp/render {file: "/path/to/presentation.md", format: "pdf"}
     
     
       
      Mistral
      model/chat
      Chat with Mistral
      model/chat {prompt: "Explain this Odoo module"}
     
     
       
      model/complete
      Text completion
      model/complete {prompt: "def calculate_"}
     
     
       
      model/embed
      Create embeddings
      model/embed {text: "Odoo payment module"}
     
     


OpenCode Tools (Local Execution)

  
    
      Category
      Tool
      Description
      Example
    
  
  
    
      File
      file/read
      Read file
      file/read {path: "/path/to/file.py"}
    
    
      
      file/write
      Write file
      file/write {path: "/path/to/file.py", content: "..."}
    
    
      
      file/search
      Search in files
      file/search {path: "/project", pattern: "def payment"}
    
    
      Terminal
      terminal/run
      Run shell command
      terminal/run {command: "kubectl get pods"}
    
    
      
      terminal/script
      Run script file
      terminal/script {path: "/scripts/deploy.sh"}
    
    
      Git
      git/status
      Git status
      git/status {path: "/project"}
    
    
      
      git/diff
      Git diff
      git/diff {path: "/project"}
    
    
      
      git/commit
      Commit changes
      git/commit {path: "/project", message: "Fix payment module"}
    
    
      LSP
      lsp/diagnostics
      Get diagnostics
      lsp/diagnostics {path: "/project/module.py"}
    
    
      
      lsp/definition
      Go to definition
      lsp/definition {path: "/project/module.py", line: 42, column: 10}
    
    
      
      lsp/completion
      Code completion
      lsp/completion {path: "/project/module.py", line: 42, column: 10}
    
  




NeoVim Commands

  
    
      Command
      Description
      Example
    
  
  
    
      :HermesAsk
      Ask Hermes a question
      :HermesAsk List Odoo modules
    
    
      :GitLabMRs
      List GitLab merge requests
      :GitLabMRs
    
    
      :GitLabIssues
      List GitLab issues
      :GitLabIssues
    
    
      :GitLabPipelines
      List GitLab pipelines
      :GitLabPipelines
    
    
      :KPods
      List Kubernetes pods
      :KPods
    
    
      :KPodsNs
      List pods in namespace
      :KPodsNs odoo
    
    
      :KNs
      List Kubernetes namespaces
      :KNs
    
    
      :KAll
      List all Kubernetes resources
      :KAll
    
    
      :KLogs
      Get pod logs
      :KLogs odoo odoo-abc123
    
    
      :DBQuery
      Run PostgreSQL query
      :DBQuery SELECT * FROM ir_module_module
    
    
      :DBUI
      Open database UI
      :DBUI
    
    
      :TFPlan
      Run Terraform plan
      :TFPlan
    
    
      :TFValidate
      Validate Terraform
      :TFValidate
    
    
      :AnsibleCheck
      Run Ansible playbook in check mode
      :AnsibleCheck playbooks/deploy-odoo.yml
    
    
      :AnsibleLint
      Lint Ansible playbook
      :AnsibleLint playbooks/deploy-odoo.yml
    
    
      :InfomaniakMails
      List Infomaniak email accounts
      :InfomaniakMails
    
    
      :InfomaniakDrive
      List kDrive files
      :InfomaniakDrive
    
    
      :InfomaniakDomains
      List Infomaniak domains
      :InfomaniakDomains
    
    
      :OdooModules
      List Odoo modules
      :OdooModules
    
    
      :OdooCall
      Call Odoo XML-RPC
      :OdooCall search_read
    
    
      :N8nList
      List N8n workflows
      :N8nList
    
    
      :N8nTrigger
      Trigger N8n workflow
      :N8nTrigger 123
     
     
      :AIToolsetHealth
      Check all service health
      :AIToolsetHealth
     
     
      :AIToolsetFeedback
      Submit feedback
      :AIToolsetFeedback
     
     
      :PlanMode
      Enter plan mode to create implementation plans
      :PlanMode
     
     
      :PlantUMLGenerate
      Generate PlantUML diagram
      :PlantUMLGenerate diagram.puml svg
     
     
      :MarpGenerate
      Generate Marp presentation
      :MarpGenerate presentation.md pdf
     
     
      :ArchitectureDiagram
      Create architecture diagram with PlantUML
      :ArchitectureDiagram "Kubernetes Cluster"
     
     
      :CreatePresentation
      Create presentation with Marp
      :CreatePresentation "Project Update"
     






📝 Workflow Examples
Example 1: Deploy Odoo Module
User: "Deploy the payment module to staging"
Hermes Workflow:

gitlab/list_mrs → Find payment module MR
gitlab/get_mr → Get MR details (source branch, commits)
kubernetes/get_pods → Check staging namespace status
postgres/query → Verify DB connection to staging
terraform/plan → Preview infrastructure changes
Ask user: "Terraform plan shows 3 changes: 1. Add payment service, 2. Update ingress, 3. Scale DB. Confirm deployment?"
If confirmed:

terraform/apply → Apply infrastructure
ansible/playbook_run → Run deployment playbook
kubernetes/get_pods → Verify deployment
gitlab/create_comment → Post deployment status to MR

Return: "✅ Payment module deployed to staging. Pods: payment-abc123 (Running), payment-xyz456 (Running). MR updated with deployment details."
Example 2: Debug Odoo Payment Issue
User: "The payment module is failing in production. Last error was 'Stripe API key invalid'"
Hermes Workflow:

kubernetes/get_pods → Find payment module pods in production
kubernetes/get_logs → Get logs from payment pods (last 100 lines)
postgres/query → Query recent payment errors: SELECT * FROM payment_logs WHERE status = 'error' ORDER BY created_at DESC LIMIT 10
model/chat → "Analyze these logs and errors. Payment module is failing with 'Stripe API key invalid'. Logs: [logs]. Errors: [errors]. What's the issue and how to fix it?"
Return: "🔍 Issue Identified: The Stripe API key in your Odoo configuration is expired. Fix: Update the key in Settings > Technical > Parameters > System Parameters for key stripe.api.key. New Key: sk_test_newkey123 (from your Stripe dashboard). Verification: After updating, test with curl -X POST https://your-odoo.com/payment/test -d '{\"amount\":100}'"
Example 3: List Company Resources
User: "Show me all our Kubernetes namespaces and GitLab projects"
Hermes Workflow:

kubernetes/get_namespaces → List all namespaces
gitlab/list_repos → List all repositories
Return:
text
Copy

📊 IT IS A SPORT RESOURCES

KUBERNETES NAMESPACES:
├─ pre-prod (Status: Active)
├─ prod (Status: Active)
├─ odoo (Status: Active)
├─ monitoring (Status: Active)
└─ dev (Status: Active)

GITLAB PROJECTS:
├─ it-is-a-sport/odoo (Last commit: 2h ago)
├─ it-is-a-sport/odoo-modules (Last commit: 1d ago)
├─ it-is-a-sport/infrastructure (Last commit: 3h ago)
├─ it-is-a-sport/ansible (Last commit: 1w ago)
└─ it-is-a-sport/terraform (Last commit: 2d ago)




Example 4: Create Backup Workflow
User: "Create a backup of the production Odoo database and upload to kDrive"
Hermes Workflow:

Ask user: "⚠️ WARNING: This will create a backup of PRODUCTION Odoo database. Confirm?"
If confirmed:

postgres/query → Run pg_dump command
terminal/run → Execute: pg_dump -h odoo-db -U user -d odoo -Fc > /backups/odoo-prod-$(date +%Y-%m-%d).dump
infomaniak/drive/upload → Upload backup to kDrive
gitlab/create_issue → Create backup log issue

Return: "✅ Backup created: odoo-prod-2024-07-13.dump (12.4MB) uploaded to kDrive/backups/. GitLab issue #1234 created with backup details."
Example 5: Check Infrastructure Health
User: "Check the health of all our services"
Hermes Workflow:

kubernetes/get_pods → Check all pods status
postgres/query → Run SELECT 1 to test DB connection
gitlab/list_mrs → Check for open MRs
infomaniak/mail/list → Check email accounts
n8n/list_workflows → Check N8n workflows
Return:
text
Copy

🏥 INFRASTRUCTURE HEALTH REPORT

✅ Kubernetes: 47/47 pods running
✅ PostgreSQL: Connection successful
✅ GitLab: 3 open MRs, 0 failed pipelines
✅ Infomaniak: 12 email accounts, 45GB kDrive used
✅ N8n: 8 workflows active
⚠️  Warning: Pod odoo-payment-abc123 has 3 restarts in last hour

Example 6: Create Implementation Plan
User: "Create a plan for adding Stripe payment integration to Odoo"
Hermes Workflow:

Use the plan mode skill to create a comprehensive implementation plan:
- Analyze requirements and current codebase
- Create markdown plan in .hermes/plans/ with bite-sized tasks
- Include file paths, code examples, and verification steps
- Follow TDD, DRY, YAGNI principles

Return: "✅ Plan created: 2026-07-25_190000-stripe-integration.md saved to .hermes/plans/"

Example 7: Generate Architecture Documentation
User: "Create architecture documentation for our Kubernetes setup with diagrams"
Hermes Workflow:

plantuml/generate → Create cluster architecture diagram
marp/generate → Generate presentation with embedded diagram
gitlab/create_file → Upload documentation to repository
Return: "✅ Architecture documentation created:
• Diagram: kubernetes-architecture.svg
• Presentation: infrastructure-overview.pdf
• Uploaded to GitLab WIKI"

Example 8: Automated Documentation Update
User: "Update our documentation when code changes are merged"
Hermes Workflow:

gitlab/list_mrs → Find merged MRs with documentation changes
plantuml/generate → Update architecture diagrams
marp/generate → Regenerate presentations
infomaniak/drive/upload → Upload to kDrive
gitlab/create_comment → Post update notification
Return: "✅ Documentation updated for 2 merged MRs:
• Updated architecture diagrams
• Regenerated presentations
• Files uploaded to kDrive/Documentation/
• Team notified in MR comments"


👥 Team Collaboration
Repository Structure
text
Copy

it-is-a-sport/
├── skills/
│   └── ai-toolset/
│       ├── SKILL.md              # This file
│       ├── README.md             # Team documentation
│       ├── CHANGELOG.md          # Version history
│       ├── CONTRIBUTING.md       # Contribution guide
│       ├── plan/
│       │   └── SKILL.md          # Plan mode skill for creating implementation plans
│       ├── .hermes/
│       │   └── plans/             # Directory for generated plans
│       └── setup/
│       │   ├── hermes-config.json
│       │   ├── neovim-setup.lua
│       │   ├── opencode-config.json
│       │   └── mcp-servers/
│       │       ├── gitlab-mcp.yaml
│       │       ├── postgres-mcp.yaml
│       │       ├── kubernetes-mcp.yaml
│       │       ├── infomaniak-mcp.yaml
│       │       ├── terraform-mcp.yaml
│       │       ├── ansible-mcp.yaml
│       │       └── n8n-mcp.yaml
│       ├── workflows/
│       │   ├── devops.yaml
│       │   ├── odoo.yaml
│       │   ├── monitoring.yaml
│       │   └── backup.yaml
│       ├── tests/
│       │   └── test_skills.lua
│       └── .gitlab-ci.yml
└── .gitignore



Contribution Guidelines


Branch Naming:

feature/xxx - New features
bugfix/xxx - Bug fixes
docs/xxx - Documentation updates
refactor/xxx - Code refactoring


Commit Messages: Follow Conventional Commits

feat: add Infomaniak MCP support
fix: correct PostgreSQL connection string
docs: update README with NeoVim commands
refactor: improve error handling in workflows


Pull Requests:

At least 1 approval required
All CI checks must pass
Include screenshots for UI changes
Update documentation (SKILL.md, README.md)


Testing:

Test in your local Hermes instance first
Verify all MCP connections work
Test NeoVim commands
Test OpenCode integration


Documentation:

Update SKILL.md with new features
Update README.md with usage examples
Add version history to CHANGELOG.md


Versioning: Follow Semantic Versioning

MAJOR - Breaking changes
MINOR - New features (backward compatible)
PATCH - Bug fixes

Version History

  
    
      Version
      Date
      Changes
      Author
    
  
  
    
      1.0.0
      2024-07-13
      Initial release: Hermes, OpenCode, NeoVim, Mistral, MCP servers (GitLab, PostgreSQL, Kubernetes, Infomaniak, Terraform, Ansible), N8n integration
      Sebastien Maurines
    
    
      1.0.1
      2024-07-14
      Added team collaboration docs, contribution guidelines
      Sebastien Maurines
    
  





⚠️ Security & Compliance
Access Control
json
Copy

{
  "accessControl": {
    "groups": {
      "devops": {
        "permissions": ["*"],
        "members": ["sebastien.maurines", "team-lead"]
      },
      "developers": {
        "permissions": [
          "mcp\:get*",
          "mcp\:list*",
          "model\:chat",
          "model\:complete",
          "kubernetes\:get*",
          "gitlab\:get*",
          "postgres\:query"
        ],
        "denied": ["kubernetes\:apply", "gitlab\:create_mr", "postgres\:write"],
        "members": ["dev1", "dev2", "dev3"]
      },
      "viewers": {
        "permissions": [
          "mcp\:get*",
          "model\:chat"
        ],
        "denied": ["*"],
        "members": ["intern1", "intern2"]
      }
    }
  }
}



Data Protection

✅ Secrets: Never logged, never stored in plain text
✅ MCP Servers: Only access allowed resources (least privilege)
✅ Network: All internal (ClusterIP), no external exposure
✅ Encryption: All communications over HTTPS/TLS
✅ Audit: All actions logged and searchable for 90 days
Compliance

GDPR: Personal data handling procedures documented
Internal Policies: Follow IT is a Sport security policies
Audit: Regular security reviews of skill and MCP servers
Rate Limiting
json
Copy

{
  "rateLimits": {
    "mcp": {
      "requestsPerMinute": 100,
      "burst": 10,
      "perUser": true
    },
    "model": {
      "requestsPerMinute": 30,
      "burst": 5,
      "perUser": true
    }
  }
}



Circuit Breaker
All MCP servers implement circuit breaker pattern:

Failure Threshold: 5 consecutive failures
Recovery Timeout: 60 seconds
Half-Open: 1 test request after timeout

🧪 Testing
Test Cases

  
    
      #
      Test
      Expected Result
      Status
    
  
  
    
      1
      MCP Connectivity
      All servers respond to health checks
      ✅
    
    
      2
      Basic Queries
      List operations work for all services
      ✅
    
    
      3
      Error Handling
      Graceful failures with clear messages
      ✅
    
    
      4
      Rate Limiting
      Enforced and logged
      ✅
    
    
      5
      Audit Trail
      All actions logged and searchable
      ✅
    
    
      6
      Team Access
      All team members can load and use the skill
      ✅
    
    
      7
      Write Operations
      Require explicit confirmation
      ✅
    
    
      8
      NeoVim Commands
      All commands work in NeoVim
      ✅
    
    
      9
      OpenCode Integration
      OpenCode can connect to Hermes
      ✅
    
    
      10
      N8n Workflows
      N8n can trigger and be triggered by Hermes
      ✅
    
  




Test Commands
bash
Copy

# Test MCP servers
kubectl exec -it hermes-pod -n pre-prod -- hermes test-mcp

# Test Hermes
hermes ask "List GitLab repositories"

# Test NeoVim
nvim +GitLabMRs
nvim +KPods
nvim +DBQuery "SELECT 1"

# Test OpenCode
opencode run "List Kubernetes pods"
opencode run "Show Odoo modules"

# Test Health Check
nvim +AIToolsetHealth



CI/CD Pipeline (.gitlab-ci.yml)
yaml
Copy

stages:
  - test
  - deploy

variables:
  KUBE_NAMESPACE: pre-prod
  HERMES_IMAGE: hermes\:latest

before_script:
  - apk add curl jq kubectl git
  - echo "\$KUBE_CONFIG" > ~/.kube/config

test_skill:
  stage: test
  image: alpine
  script:
    - |
      # Test MCP server health
      for server in gitlab postgres kubernetes infomaniak terraform ansible n8n; do
        echo "Testing \$server MCP server..."
        kubectl exec -it hermes-pod -n \$KUBE_NAMESPACE -- curl -s http://\$server-mcp:3000/health | jq -e '.status == "ok"'
      done
    - |
      # Test Hermes skill loading
      kubectl exec -it hermes-pod -n \$KUBE_NAMESPACE -- hermes test-skill ai-toolset

deploy_skill:
  stage: deploy
  image: bitnami/kubectl
  script:
    - kubectl apply -f setup/mcp-servers/ -n \$KUBE_NAMESPACE
    - kubectl rollout restart deployment/hermes -n \$KUBE_NAMESPACE
  only:
    - main
  when: manual




📚 Documentation Standards
SKILL.md

Always up-to-date with latest features
Clear examples for each tool
Version history maintained
README.md (Team Documentation)
markdown
Copy

# AI Toolset - IT is a Sport

## 🎯 Overview
Centralized AI-powered DevOps assistant for IT is a Sport team.

## 🚀 Getting Started

### Prerequisites
- [Hermes](#) deployed in Kubernetes
- [OpenCode](#) installed locally
- [NeoVim](#) ≥ 0.9.0

### Installation
1. Clone this repository
2. Deploy MCP servers
3. Configure Hermes
4. Setup NeoVim

### Usage
See [SKILL.md](SKILL.md) for complete documentation.

## 📞 Support
- **Issues**: [GitLab Issues](https://gitlab.com/it-is-a-sport/skills/-/issues)
- **Questions**: #devops channel in Slack
- **Urgent**: @devops-team in Slack

## 👥 Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md)



CONTRIBUTING.md
markdown
Copy

# Contributing to AI Toolset

## 📝 How to Contribute
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a merge request

## 🎯 Contribution Guidelines
- Follow the existing code style
- Add tests for new features
- Update documentation
- Keep changes focused

## 📋 Pull Request Template
```markdown
## Description
[Describe your changes]

## Related Issues
[Link to relevant issues]

## Testing
- [ ] Tested locally
- [ ] All MCP servers working
- [ ] NeoVim commands tested
- [ ] OpenCode integration tested

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added
- [ ] CHANGELOG updated



text
Copy

---

## 🎯 **Best Practices**

### **✅ DO:**
1. **Start small** - Begin with core functionality, expand gradually
2. **Document everything** - Assume new team members know nothing
3. **Test thoroughly** - Every change should be tested before MR
4. **Use feature flags** - Enable new features gradually
5. **Monitor usage** - Track which tools are used most
6. **Iterate based on feedback** - Regular team retrospectives
7. **Keep it maintainable** - Clear structure, good naming
8. **Security first** - Review all MCP permissions
9. **Version control** - All changes in GitLab
10. **Backup** - Regular backups of skill configurations

### **❌ DON'T:**
1. **Hardcode environment-specific values** - Use environment variables
2. **Assume everyone has same setup** - Document prerequisites clearly
3. **Make breaking changes** - Maintain backward compatibility
4. **Ignore security** - Always review permissions
5. **Overcomplicate** - Keep it simple and focused
6. **Skip testing** - Untested skills break production
7. **Document only for experts** - Write for beginners
8. **Use latest features immediately** - Wait for stability
9. **Work in isolation** - Involve the team early
10. **Forget error handling** - Graceful failures are crucial

---

## 🚨 **Troubleshooting**

| Issue | Diagnosis | Solution |
|-------|-----------|----------|
| MCP server not responding | `kubectl get pods -n pre-prod \| grep mcp` shows CrashLoopBackOff | Check logs: `kubectl logs -n pre-prod pod/gitlab-mcp` |
| Permission denied | "Access denied" error when calling MCP tool | Verify Hermes access control and MCP server permissions |
| Rate limit exceeded | "Rate limit exceeded" error | Wait 1 minute or increase limits in `hermes-config.json` |
| Model errors | "Model not available" or "API key invalid" | Check Mistral API key in Hermes config |
| NeoVim commands not working | Command not found | Verify plugin installation: `:checkhealth` in NeoVim |
| OpenCode not connecting | Connection refused | Check Hermes endpoint and OpenCode config |
| N8n workflows not triggering | Workflow not found | Verify N8n MCP server is running and workflow IDs |
| Database connection failed | PostgreSQL connection error | Verify connection string in MCP server config |
| Kubernetes access denied | RBAC permission error | Check Kubernetes ServiceAccount permissions |

**Support**:
- Open an issue: [GitLab Issues](https://gitlab.com/it-is-a-sport/skills/-/issues)
- Slack: #devops
- Email: devops@it-is-a-sport.com

---



