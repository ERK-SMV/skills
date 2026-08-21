# GitLab MCP Server - Known Issues and Workarounds

## Current Status (2026-08-12)

**MCP Server**: `@modelcontextprotocol/server-gitlab`
**Status**: Partially functional with known stability issues
**Version**: Unknown (latest from npm)

## Known Issues

### Issue 1: "Cannot read properties of undefined"

**Affected Tools**:
- `mcp__gitlab__search_repositories`
- `mcp__gitlab__get_file_contents`

**Symptoms**:
```
Error: Cannot read properties of undefined (reading 'map')
```

**Root Cause**:
- MCP server not properly handling GitLab API responses
- Missing error handling for 404/403 responses
- Race condition in response parsing

**Workaround**:
Use direct REST API calls instead:
```bash
# Instead of MCP tool
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects?search=query&per_page=100"
```

**Tracking**:
- First observed: 2026-07-26
- Last confirmed: 2026-08-12
- Status: Open

### Issue 2: Project Not Found (404)

**Symptoms**:
```
{"message":"404 Project Not Found"}
```

**Root Causes**:
1. User not actually member of project (GUI ≠ API)
2. Membership not propagated to API yet
3. Wrong project path/namespace
4. Project visibility restrictions

**Diagnosis**:
```bash
# Check if user is member (admin)
curl -s --header "PRIVATE-TOKEN: ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/PROJECT_PATH/members/all/USER_ID"

# List user's accessible projects
curl -s --header "PRIVATE-TOKEN: USER_TOKEN" \
  "https://gitlab.com/api/v4/projects?membership=true"
```

**Solutions**:
1. Add user to project with correct role
2. Wait 5-10 minutes for propagation
3. Verify exact project path
4. Check project visibility settings

### Issue 3: Email Not Confirmed

**Error**:
```
403 Forbidden - Your primary email address is not confirmed
```

**Solution**:
```bash
# Resend confirmation
curl -s "https://gitlab.com/users/confirmation/new" \
  -d "email=user@email.com"

# Verify confirmation
curl -s --header "PRIVATE-TOKEN: TOKEN" \
  "https://gitlab.com/api/v4/user" \
  | python3 -c "import sys,json; u=json.load(sys.stdin); print('Confirmed:', u.get('confirmed_at') is not None)"
```

## Working Tools

### ✅ Functional MCP Tools

| Tool | Status | Notes |
|------|--------|-------|
| `mcp__gitlab__create_repository` | ✅ Working | Creates projects successfully |
| `mcp__gitlab__create_branch` | ✅ Working | Branch creation works |
| `mcp__gitlab__create_issue` | ✅ Working | Issue creation stable |
| `mcp__gitlab__create_merge_request` | ✅ Working | MR creation functional |

### ⚠️ Unstable MCP Tools

| Tool | Status | Issue |
|------|--------|-------|
| `mcp__gitlab__search_repositories` | ⚠️ Unstable | "Cannot read properties of undefined" |
| `mcp__gitlab__get_file_contents` | ⚠️ Unstable | Same error as search |
| `mcp__gitlab__list_projects` | ⚠️ Unstable | Inconsistent results |

## Recommended Approach

### Priority Order for GitLab Operations

1. **Direct REST API** (Most reliable)
2. **MCP Tools** (For working operations only)
3. **Fallback to REST** (When MCP fails)

### Configuration Pattern

```yaml
# ~/.hermes/config.yaml
mcp_servers:
  gitlab:
    command: npx
    args:
      - -y
      - '@modelcontextprotocol/server-gitlab'
      - 'https://gitlab.com'  # or self-hosted URL
    env:
      GITLAB_PERSONAL_ACCESS_TOKEN: your_token_here
    enabled: true
```

### Error Handling Pattern

```python
import subprocess
import json

def safe_mcp_call(tool_name, arguments):
    """Call MCP tool with fallback to REST API"""
    try:
        # Try MCP first
        result = subprocess.run([
            "tool_call", "name=" + tool_name, "arguments=" + arguments
        ], capture_output=True, text=True, timeout=15)
        
        if result.returncode == 0:
            return json.loads(result.stdout)
        else:
            raise Exception("MCP call failed")
    except Exception as e:
        # Fallback to REST API
        print(f"MCP failed, falling back to REST: {str(e)}")
        return direct_api_call(tool_name, arguments)

def direct_api_call(tool_name, arguments):
    """Direct REST API implementation"""
    # Implement REST API call for the operation
    pass
```

## Troubleshooting Checklist

### MCP Server Issues

1. ✅ Verify MCP server is configured
   ```bash
   hermes config get mcp_servers.gitlab
   ```

2. ✅ Check token is valid
   ```bash
   curl -s --header "PRIVATE-TOKEN: TOKEN" "https://gitlab.com/api/v4/user"
   ```

3. ✅ Test simple MCP operation
   ```bash
   tool_call name="mcp__gitlab__create_issue" arguments='{"project":"test/project","title":"Test","description":"Test"}'
   ```

4. ✅ Fallback to REST API
   ```bash
   curl -s --header "PRIVATE-TOKEN: TOKEN" "https://gitlab.com/api/v4/projects?search=query"
   ```

### Access Issues

1. ✅ Verify user is member of project
2. ✅ Check access level (minimum Reporter/20)
3. ✅ Confirm email is verified
4. ✅ Test with different branches
5. ✅ Verify exact project path

## Performance Comparison

| Operation | MCP (ms) | REST (ms) | Reliability |
|-----------|----------|-----------|-------------|
| Search repos | 800-1200 | 200-400 | ❌ Unstable |
| Get file | 600-1000 | 150-300 | ❌ Unstable |
| Create issue | 400-600 | 250-350 | ✅ Stable |
| Create branch | 500-700 | 300-400 | ✅ Stable |

## Migration Path

### From MCP to REST

```bash
# Old MCP approach (unstable)
tool_call name="mcp__gitlab__search_repositories" arguments='{"search":"project"}'

# New REST approach (reliable)
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects?search=project&per_page=100"
```

### Configuration Update

```yaml
# Old configuration (may have issues)
mcp_servers:
  gitlab:
    command: npx
    args: ['@modelcontextprotocol/server-gitlab']

# New configuration (explicit)
mcp_servers:
  gitlab:
    command: npx
    args:
      - -y
      - '@modelcontextprotocol/server-gitlab'
      - 'https://gitlab.com'
    env:
      GITLAB_PERSONAL_ACCESS_TOKEN: token_here
    timeout: 30000
    retries: 3
```

## Updates

### 2026-08-12

- Confirmed MCP search and file tools still unstable
- Added email confirmation issue
- Updated workaround patterns
- Added performance comparison

### 2026-07-26

- First documented MCP stability issues
- Identified "Cannot read properties of undefined" error
- Established REST API fallback pattern

## References

- GitLab API Documentation: https://docs.gitlab.com/ee/api/
- MCP Server GitHub: https://github.com/modelcontextprotocol/server-gitlab
- Hermes MCP Configuration: https://hermes-agent.nousresearch.com/docs/mcp

## Status

**Current Recommendation**: Use REST API for repository search and file operations. MCP tools work for create operations but are unstable for read operations.

**Monitor**: Check MCP server updates monthly. Test stability before relying on MCP for critical operations.