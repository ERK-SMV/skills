# GitLab Access Troubleshooting Guide

## Session: 2026-08-12 - Access Level Issues

### Problem Summary

**User**: hermers_agent (test_hermes)
**Issue**: Developer role assigned but no project access
**Project**: smv-erk-coding/2.erk-infra
**Branch**: test

### Symptoms

1. User shows as "Developer" in project members
2. `membership=true` returns 0 projects
3. Direct project access returns 404
4. Search for project returns 0 results

### Root Causes

1. **User not actually added to project** - Role assignment UI showed "Developer" but membership API showed no access
2. **Email not confirmed** - Initial attempts failed with "403 Forbidden - Your primary email address is not confirmed"
3. **Wrong branch name** - "test" branch may not exist

### Solutions

#### 1. Verify and Add User

```bash
# Check if user is actually member (admin required)
curl -s --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/smv-erk-coding%2F2.erk-infra/members/all/41218069"

# Add user with Reporter role (minimum for MCP)
curl -X POST --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/smv-erk-coding%2F2.erk-infra/members" \
  -d "user_id=41218069" \
  -d "access_level=20"
```

#### 2. Confirm Email

```bash
# Check email confirmation status
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user" \
  | python3 -c "import sys,json; u=json.load(sys.stdin); print(f'Email: {u.get(\"email\")}'); print(f'Confirmed: {u.get(\"confirmed_at\") is not None}')"

# Resend confirmation if needed
curl -s "https://gitlab.com/users/confirmation/new" \
  -d "email=user@email.com"
```

#### 3. Test Different Branches

```bash
# List all branches
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/PROJECT_ID/repository/branches" \
  | python3 -c "import sys,json; [print(b['name']) for b in json.load(sys.stdin)]"

# Test common branch names
for ref in main master lab test develop dev; do
  echo "Testing branch: $ref"
  curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://gitlab.com/api/v4/projects/PROJECT_ID/repository/tree?path=platform/passbolt&ref=$ref"
done
```

#### 4. Verify Project Existence

```bash
# Check if project exists (admin)
curl -s --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects/smv-erk-coding%2F2.erk-infra"

# Search for similar projects
curl -s --header "PRIVATE-TOKEN: YOUR_ADMIN_TOKEN" \
  "https://gitlab.com/api/v4/projects?search=erk-infra"
```

### Access Level Requirements

| MCP Operation | Minimum Level | Role Name | Notes |
|---------------|---------------|-----------|-------|
| Read repository | 20 | Reporter | Sufficient for MCP server |
| List projects | 20 | Reporter | See accessible projects |
| Read file contents | 20 | Reporter | Get file contents |
| Create issues | 20 | Reporter | Create new issues |
| Write repository | 30 | Developer | Push code |
| Manage CI/CD | 40 | Maintainer | Configure pipelines |

**Recommendation**: Use Reporter (20) for MCP server - provides full read access without write permissions.

### Testing Script

```python
#!/usr/bin/env python3
"""
Test GitLab Access - Comprehensive Test
"""
import subprocess
import json
import os

def run_curl(url, token):
    cmd = ["curl", "-s", "-X", "GET", url, "-H", f"PRIVATE-TOKEN: {token}"]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    return result.stdout if result.returncode == 0 else f"Error: {result.stderr}"

def test_access():
    token = os.getenv("GITLAB_COM_TOKEN", "")
    if not token:
        print("❌ No token found")
        return
    
    # Test user info
    user_data = run_curl("https://gitlab.com/api/v4/user", token)
    user = json.loads(user_data)
    print(f"User: {user['username']} ({user['name']})")
    print(f"Confirmed: {user.get('confirmed_at') is not None}")
    
    # Test project access
    projects = json.loads(run_curl("https://gitlab.com/api/v4/projects?membership=true", token))
    print(f"Accessible projects: {len(projects)}")
    
    # Test specific project
    project_data = run_curl("https://gitlab.com/api/v4/projects/smv-erk-coding%2F2.erk-infra", token)
    try:
        project = json.loads(project_data)
        if "id" in project:
            print(f"✅ Project access: {project['name']}")
        else:
            print(f"❌ Project access: {project_data}")
    except json.JSONDecodeError:
        print(f"❌ Project access: {project_data}")

if __name__ == "__main__":
    test_access()
```

### Common Error Patterns

#### 404 Project Not Found

**Causes**:
- User not member of project
- Project doesn't exist
- Wrong project path
- Private project without access

**Solutions**:
1. Verify project exists with admin token
2. Add user to project with Reporter role
3. Check exact project path
4. Verify project visibility

#### 403 Forbidden - Email Not Confirmed

**Solution**:
1. Check email inbox for confirmation
2. Resend confirmation: https://gitlab.com/users/confirmation/new
3. Confirm email via API

#### 401 Unauthorized

**Causes**:
- Invalid token
- Expired token
- Token for wrong instance
- Missing scopes

**Solutions**:
1. Verify token at: https://gitlab.com/-/profile/personal_access_tokens
2. Check scopes: need `read_api`, `read_repository`
3. Test which instance token belongs to

### Best Practices

1. **Use Reporter role (20)** for MCP server - minimum sufficient access
2. **Verify membership** with admin token before troubleshooting
3. **Test with multiple branch names** - don't assume branch exists
4. **Check email confirmation** - common issue with new users
5. **Use project access tokens** for automated systems

### Files Created During Session

- `/tmp/get_passbolt_files.py` - File retrieval script
- `/tmp/check_gitlab_tokens.py` - Token checking script
- `/tmp/gitlab_final_solution.md` - Access solution
- `/tmp/gitlab_token_solution.md` - Token analysis
- `/tmp/gitlab_troubleshooting_guide.md` - Troubleshooting guide

### Lessons Learned

1. **Role assignment ≠ membership** - User must be added to project
2. **Email confirmation required** - Blocks API access for new users
3. **Reporter sufficient for MCP** - No need for Developer role
4. **Test multiple branches** - Branch names vary
5. **Verify with admin token** - User token may not show all info