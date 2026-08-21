---
name: gitlab-repo-management
description: "GitLab repository management via MCP tools and REST API."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [GitLab, Repositories, MCP, API, Management]
    related_skills: [github-repo-management, github-mcp-tools]
---

# GitLab Repository Management

Create, clone, discover, and manage GitLab repositories. This skill covers both MCP-based operations (when available) and direct REST API approaches for reliability.

## Prerequisites

### Authentication

GitLab uses Personal Access Tokens or Project Access Tokens:

1. **Create a token**: https://gitlab.com/-/profile/personal_access_tokens (for gitlab.com) or your self-hosted instance URL
2. **Required scopes**: `read_api`, `read_repository` (for read operations)
3. **Store securely**: Use environment variables or Hermes config

### Access Levels

**Minimum access levels required for MCP operations:**

| Operation | Required Level | Role Name | Description |
|-----------|----------------|-----------|-------------|
| Read repository | 20 | Reporter | View files, branches, commits |
| List projects | 20 | Reporter | See project structure |
| Read issues | 20 | Reporter | View issues and comments |
| Create issues | 20 | Reporter | Create new issues |
| Write repository | 30 | Developer | Push code, create branches |
| Manage CI/CD | 40 | Maintainer | Configure pipelines |

**Note**: MCP server only needs Reporter (20) for most read operations. Developer (30) is only needed for write operations.

## Common Issues

### User Has Role But No Access

**Symptoms**: User shows as "Developer" but `membership=true` returns 0 projects.

**Causes**:
1. User not actually added to project (role assignment failed)
2. Project name/namespace is incorrect
3. User added to wrong project

**Solutions**:
```bash
# Verify user is member of project (admin required)
curl -s --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/PROJECT_PATH/members/all/USER_ID"

# Add user with correct access level
curl -X POST --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/PROJECT_PATH/members" \
  -d "user_id=USER_ID" \
  -d "access_level=20"
```

### Project Not Found (404)

**Diagnosis**:
```bash
# Check if project exists at all
curl -s --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/PROJECT_PATH"

# Search for similar projects
curl -s --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects?search=PROJECT_NAME"
```

**Common fixes**:
- Verify exact project path (namespace/project)
- Check for typos in project name
- Confirm project visibility (private projects need explicit access)

### Email Not Confirmed

**Error**: "403 Forbidden - Your primary email address is not confirmed"

**Solution**:
```bash
# Resend confirmation email
curl -s "https://gitlab.com/users/confirmation/new" \
  -d "email=user@email.com"

# Verify email status
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user" \
  | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'Confirmed: {u.get(\"confirmed_at\") is not None}')"
```

### Branch Not Found

**Try different branch names**:
```bash
# List available branches
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/PROJECT_ID/repository/branches" \
  | python3 -c "import sys,json; [print(b['name']) for b in json.load(sys.stdin)]"

# Test common branch names
test_refs=["main", "master", "lab", "test", "develop", "dev"]
for ref in test_refs:
  echo "Testing branch: $ref"
  curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://gitlab.com/api/v4/projects/PROJECT_ID/repository/tree?path=platform/passbolt&ref=$ref"
```

### Configuration in Hermes

```yaml
# ~/.hermes/config.yaml
mcp_servers:
  gitlab:
    command: npx
    args:
      - -y
      - '@modelcontextprotocol/server-gitlab'
      - 'https://gitlab.com'  # or your self-hosted instance
    env:
      GITLAB_PERSONAL_ACCESS_TOKEN: your_token_here
    enabled: true
```

**Important**: If using a self-hosted GitLab instance, replace `https://gitlab.com` with your instance URL.

## Available Tools

### MCP Tools (When Available)

| Tool | Purpose | Status |
|------|---------|--------|
| `mcp__gitlab__search_repositories` | Search for projects | ⚠️ Known issues |
| `mcp__gitlab__get_file_contents` | Get file/directory contents | ⚠️ Known issues |
| `mcp__gitlab__create_repository` | Create new project | ✅ Working |
| `mcp__gitlab__create_branch` | Create branch | ✅ Working |
| `mcp__gitlab__create_issue` | Create issue | ✅ Working |
| `mcp__gitlab__create_merge_request` | Create merge request | ✅ Working |

**Note**: Search and file listing tools currently have stability issues. Use REST API workarounds below.

### REST API Tools (Recommended)

All GitLab operations can be performed via the REST API when MCP tools are unstable.

## Common Workflows

### 1. Count Your Repositories

**Problem**: `mcp__gitlab__search_repositories` returns `Cannot read properties of undefined (reading 'map')`

**Solution - Direct API**:
```bash
# For gitlab.com
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects?owned=true&per_page=100" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'GitLab projects: {len(data)}')
for p in data:
    print(f'- {p[\"name\"]:30}  {p[\"path_with_namespace\"]}')"

# For self-hosted instance
INSTANCE="https://your-gitlab-server.com"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$INSTANCE/api/v4/projects?owned=true&per_page=100" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Projects: {len(data)}')"
```

**Using MCP (if working)**:
```
tool_call name="mcp__gitlab__search_repositories" arguments='{}'
```

### 2. List Repository Structure

**Problem**: `mcp__gitlab__get_file_contents` may fail with same error as search

**Solution - Direct API**:
```bash
# Get project ID first
PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects?owned=true&per_page=1" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

# List repository tree (root directory)
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/tree?path=&recursive=false" \
  | python3 -c "
import sys, json
for item in json.load(sys.stdin):
    print(f'{item[\"type\"]:10}  {item[\"name\"]}')"

# List all files recursively
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/tree?recursive=true" \
  | python3 -c "
import sys, json
for item in json.load(sys.stdin):
    if item['type'] == 'blob':
        print(f'FILE: {item[\"path\"]}')
    elif item['type'] == 'tree':
        print(f'DIR:  {item[\"path\"]}/')"
```

### 3. Clone a Repository

```bash
# HTTPS (requires token in URL or credential helper)
git clone https://gitlab.com/username/project.git

# With token in URL
git clone https://oauth2:$GITLAB_TOKEN@gitlab.com/username/project.git

# SSH (requires SSH key configured in GitLab)
git clone git@gitlab.com:username/project.git

# Self-hosted
git clone https://your-instance.com/username/project.git
```

### 4. Create a New Repository

**With MCP**:
```
tool_call name="mcp__gitlab__create_repository" arguments='{"name": "my-new-project", "description": "Project description", "visibility": "private"}'
```

**With REST API**:
```bash
# For user namespace
curl -s -X POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects" \
  -d "name=my-new-project" \
  -d "description=Project description" \
  -d "visibility=private" \
  -d "initialize_with_readme=true"

# For group namespace
GROUP_ID=12345
curl -s -X POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects" \
  -d "name=my-new-project" \
  -d "namespace_id=$GROUP_ID" \
  -d "visibility=private"
```

### 5. Get Repository Information

```bash
# Get project details
PROJECT_PATH="username/project-name"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_PATH" \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'Name: {p[\"name\"]}')
print(f'Description: {p.get(\"description\", \"N/A\")}')
print(f'Visibility: {p[\"visibility\"]}')
print(f'Default branch: {p[\"default_branch\"]}')
print(f'HTTP URL: {p[\"http_url_to_repo\"]}')
print(f'SSH URL: {p[\"ssh_url_to_repo\"]}')"
```

### 6. Create and Manage Branches

**With MCP**:
```
tool_call name="mcp__gitlab__create_branch" arguments='{"project": "username/project", "branch": "feature/new-feature", "ref": "main"}'
```

**With REST API**:
```bash
PROJECT_ID=12345
# Create branch from main
curl -s -X POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/branches" \
  -d "branch=feature/new-feature" \
  -d "ref=main"

# List all branches
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/branches" \
  | python3 -c "
import sys, json
for b in json.load(sys.stdin):
    print(f'{b[\"name\"]:30}  {b[\"commit\"][\"id\"][:8]}  {b[\"protected\"]}')"

# Delete branch
curl -s -X DELETE \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/repository/branches/feature%2Fnew-feature"
```

## Rate Limits

| Access Level | Rate Limit |
|--------------|------------|
| Unauthenticated (shared IP) | 600 requests/minute |
| Authenticated | 10,000 requests/minute |

**Check your rate limit**:
```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user" \
  | grep -i rate
```

## Troubleshooting

### Error: "401 Unauthorized"

**Causes**:
1. Invalid or expired token
2. Token missing required scopes
3. Token for wrong GitLab instance (gitlab.com vs self-hosted)

**Solutions**:
1. Verify token at: https://gitlab.com/-/profile/personal_access_tokens
2. Check scopes: need at least `read_api` for most operations
3. Test which instance the token belongs to:
   ```bash
   # Test gitlab.com
   curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/user"
   
   # Test self-hosted
   curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://your-instance.com/api/v4/user"
   ```

### Error: "404 Not Found"

**Causes**:
1. Project doesn't exist
2. You don't have access to the project
3. Wrong project path/ID

**Solutions**:
1. Verify project exists and you have access
2. Use full path: `group/subgroup/project`
3. Get your accessible projects: `curl "https://gitlab.com/api/v4/projects?membership=true"`

### Error: "500 Internal Server Error"

**Causes**:
1. GitLab server issue
2. API bug

**Solutions**:
1. Wait and retry
2. Check GitLab status: https://status.gitlab.com
3. Try a different endpoint

### MCP Tools Returning "Cannot read properties of undefined"

**Status**: Known issue with GitLab MCP server

**Workaround**: Use direct REST API calls as shown in this skill

**Tracking**: See `references/gitlab-mcp-issues.md` for updates

### Error: "404 Not Found"

**Causes**:
1. Project doesn't exist
2. You don't have access to the project
3. Wrong project path/ID

**Solutions**:
1. Verify project exists and you have access
2. Use full path: `group/subgroup/project`
3. Get your accessible projects: `curl "https://gitlab.com/api/v4/projects?membership=true"`

## API Endpoints Reference

| Resource | Endpoint | Method | Description |
|----------|----------|--------|-------------|
| Current user | `/api/v4/user` | GET | Get authenticated user info |
| User projects | `/api/v4/users/:user_id/projects` | GET | List projects owned by user |
| All projects | `/api/v4/projects` | GET | List all accessible projects |
| Owned projects | `/api/v4/projects?owned=true` | GET | List projects you own |
| Group projects | `/api/v4/groups/:group_id/projects` | GET | List projects in a group |
| Project info | `/api/v4/projects/:id` | GET | Get project details |
| Repository tree | `/api/v4/projects/:id/repository/tree` | GET | List files/directories |
| File contents | `/api/v4/projects/:id/repository/files/:path` | GET | Get file contents |
| Create project | `/api/v4/projects` | POST | Create new project |
| Create branch | `/api/v4/projects/:id/repository/branches` | POST | Create new branch |
| List branches | `/api/v4/projects/:id/repository/branches` | GET | List all branches |

## Akretion GitLab Instance

For users working with Akretion's self-hosted GitLab instance:

**Instance URL**: `https://gitlab.akretion.com`
**API Base**: `https://gitlab.akretion.com/api/v4/`
**Token Variable**: `GITLAB_AK_TOKEN`

### Common Operations

```bash
# List projects you have access to
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true&per_page=100"

# Get project details
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe"

# List repository tree
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe/repository/tree"
```

### Known Repositories

- **fnfe**: Main infrastructure and Odoo repository
- **fnfempe**: Additional Odoo and migration components

See `references/akretion-gitlab-repositories.md` for detailed repository structures.

## Akretion GitLab Instance

For users working with Akretion's self-hosted GitLab instance:

**Instance URL**: `https://gitlab.akretion.com`
**API Base**: `https://gitlab.akretion.com/api/v4/`
**Token Variable**: `GITLAB_AK_TOKEN`

### Common Operations

```bash
# List projects you have access to
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true&per_page=100"

# Get project details
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe"

# List repository tree
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe/repository/tree"
```

### Known Repositories

- **fnfe**: Main infrastructure and Odoo repository
- **fnfempe**: Additional Odoo and migration components

See `references/akretion-gitlab-repositories.md` for detailed repository structures.

1. **Always use HTTPS** for API calls with tokens
2. **Use environment variables** for tokens, never hardcode
3. **Handle pagination** for large result sets
4. **Use `per_page=100`** (max) to minimize API calls
5. **Cache results** when possible to avoid rate limits
6. **Prefer REST API** when MCP tools are unstable
7. **Verify instance URL** - tokens are instance-specific

## Comparison: GitLab vs GitHub

| Operation | GitLab | GitHub |
|-----------|--------|--------|
| Auth header | `PRIVATE-TOKEN` | `Authorization: token` |
| Rate limit | 10,000/min | 5,000/hour |
| User repos | `/api/v4/user/projects` | `/user/repos` |
| Search | `/api/v4/projects?search=query` | `/search/repositories` |
| File tree | `/repository/tree` | `/contents/path` |
| Create repo | POST `/projects` | POST `/user/repos` |

## Linked Reference Files

- `references/akretion-gitlab-repositories.md` - Akretion GitLab instance repositories and access patterns
- `references/gitlab-mcp-issues.md` - Known MCP server issues and workarounds
- `references/gitlab-session-20260726.md` - Session notes from repository counting investigation
- `references/gitlab-access-troubleshooting.md` - Access level requirements and troubleshooting guide

## See Also

- `github-repo-management`: GitHub equivalent operations
- `github-mcp-tools`: GitHub MCP tools usage patterns