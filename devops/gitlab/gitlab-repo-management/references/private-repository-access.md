# Private Repository Access Guide

## Common Issues and Solutions

### Issue: "404 Not Found" When Accessing Private Repositories

**Common Causes:**
1. Repository is private and requires authentication
2. Token doesn't have sufficient permissions
3. Wrong repository path or instance URL
4. Repository doesn't exist

### Solution: Proper Authentication

#### Method 1: Using Personal Access Token

```bash
# Set your token as environment variable
export GITLAB_TOKEN="your_personal_access_token"

# Test authentication
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user"
```

#### Method 2: Using Project Access Token

```bash
# For specific projects, use project access tokens
# Create token in: Project Settings > Access Tokens
export GITLAB_TOKEN="your_project_access_token"
```

### Solution: Accessing Files in Private Repositories

#### Get File Content

```bash
# Get raw file content from private repository
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/namespace%2Fproject/repository/files/path%2Fto%2Ffile/raw" \
  -o local_filename

# Example with URL encoding
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/akretion%2Ffnfe/repository/files/dev_infra%2Fmigration%2Fitipart-invoices.py/raw" \
  -o itipart-invoices.py
```

#### List Repository Tree

```bash
# List files in a directory
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/namespace%2Fproject/repository/tree?path=directory_path"

# Example
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/akretion%2Ffnfe/repository/tree?path=dev_infra/migration"
```

#### Search for Files

```bash
# Search recursively for files
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/namespace%2Fproject/repository/tree?recursive=true" \
  | grep -i "search_term"

# Example: Find invoice-related files
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/akretion%2Ffnfe/repository/tree?recursive=true" \
  | grep -i "invoice"
```

### Solution: Cloning Private Repositories

#### HTTPS with Token

```bash
# Clone using HTTPS with token in URL
git clone https://oauth2:$GITLAB_TOKEN@gitlab.com/namespace/project.git

# Or configure credential helper
git config --global credential.helper store
git clone https://gitlab.com/namespace/project.git
```

#### SSH (Recommended)

```bash
# Add SSH key to GitLab
# 1. Generate SSH key: ssh-keygen -t ed25519
# 2. Add to GitLab: Settings > SSH Keys
# 3. Clone using SSH
git clone git@gitlab.com:namespace/project.git
```

### Solution: Akretion GitLab Instance

For Akretion's self-hosted GitLab:

```bash
# Set Akretion token
export GITLAB_AK_TOKEN="your_akretion_token"

# Use Akretion instance URL
INSTANCE="https://gitlab.akretion.com"

# Get file from Akretion repository
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "$INSTANCE/api/v4/projects/akretion%2Ffnfe/repository/files/dev_infra%2Fmigration%2Fitipart-invoices.py/raw" \
  -o itipart-invoices.py
```

### Solution: Common Error Patterns

#### Error: "404 Not Found"

```bash
# Check if repository exists
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/namespace%2Fproject"

# List accessible projects
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects?membership=true"
```

#### Error: "403 Forbidden"

```bash
# Check token permissions
# Token needs: read_api, read_repository, write_repository (for writes)

# Verify token is valid
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user"
```

#### Error: "401 Unauthorized"

```bash
# Token is invalid or expired
# 1. Create new token: https://gitlab.com/-/profile/personal_access_tokens
# 2. Verify token works
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user"
```

### Best Practices

1. **Use environment variables** for tokens
2. **Never hardcode tokens** in scripts
3. **Use HTTPS with tokens** for API calls
4. **Prefer SSH for git operations**
5. **Handle errors gracefully** in scripts
6. **Check repository existence** before operations
7. **Use proper URL encoding** for paths

### Debugging Checklist

```bash
# 1. Verify token is set
echo $GITLAB_TOKEN

# 2. Test basic authentication
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/user"

# 3. Check repository access
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/namespace%2Fproject"

# 4. Test file access
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/namespace%2Fproject/repository/tree?path=directory"
```

### Python Example

```python
import requests
import os

# Get token from environment
GITLAB_TOKEN = os.getenv('GITLAB_TOKEN')
if not GITLAB_TOKEN:
    raise ValueError("GITLAB_TOKEN environment variable not set")

# Headers for API calls
headers = {
    'PRIVATE-TOKEN': GITLAB_TOKEN
}

# Get file content
def get_file_content(project_path, file_path):
    """Get file content from private repository"""
    # URL encode the file path
    encoded_path = file_path.replace('/', '%2F')
    
    url = f"https://gitlab.com/api/v4/projects/{project_path}/repository/files/{encoded_path}/raw"
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    return response.text

# Example usage
try:
    content = get_file_content(
        'akretion/fnfe',
        'dev_infra/migration/itipart-invoices.py'
    )
    
    # Save to file
    with open('itipart-invoices.py', 'w') as f:
        f.write(content)
    
    print("✅ Successfully downloaded file")
    
except requests.exceptions.HTTPError as e:
    print(f"❌ Error: {e}")
    print("Check:")
    print("  - Token is valid")
    print("  - Repository path is correct")
    print("  - File path is correct")
    print("  - You have access to the repository")
```

### Troubleshooting Flowchart

```
[Start]
  │
  ▼
Error accessing private repository?
  │
  ▼
  ├─ 404 Not Found ─────────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Check repository exists? ───────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
  ├─ Yes ─────────────────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Check path is correct? ───────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
  ├─ Yes ─────────────────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Check token permissions ─────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
  ├─ No ──────────────────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Fix repository path/name ─────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
  └─ No ──────────────────────────────────────────────────────────────────────────────►
     │                                                                                      │
     ▼                                                                                      │
     Repository doesn't exist or you don't have access ─────────────────────────────────►
     │                                                                                      │
     ▼                                                                                      │
  ├─ 403 Forbidden ────────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Check token permissions ─────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
  ├─ Insufficient ───────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Add required scopes to token ────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
  └─ Sufficient ─────────────────────────────────────────────────────────────────────►
     │                                                                                      │
     ▼                                                                                      │
     Check repository visibility settings ────────────────────────────────────────────►
     │                                                                                      │
     ▼                                                                                      │
  ├─ 401 Unauthorized ─────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Token is invalid or expired ─────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
Create new token ────────────────────────────────────────────────────────────────────►
  │                                                                                      │
  ▼                                                                                      │
[End]
```

### Security Best Practices

1. **Never commit tokens** to version control
2. **Use short-lived tokens** when possible
3. **Restrict token scopes** to minimum required
4. **Rotate tokens regularly**
5. **Use environment variables** for token storage
6. **Revoke unused tokens**
7. **Monitor token usage** in GitLab

### Token Management

```bash
# Create new token
# https://gitlab.com/-/profile/personal_access_tokens

# List active tokens (GitLab Premium/Ultimate)
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/personal_access_tokens"

# Revoke token (GitLab Premium/Ultimate)
curl -s -X DELETE \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/personal_access_tokens/TOKEN_ID"
```

### Required Token Scopes

| Operation | Required Scopes |
|-----------|-----------------|
| Read repository | `read_api`, `read_repository` |
| Write repository | `read_api`, `read_repository`, `write_repository` |
| Create projects | `api` |
| Manage issues | `api` |
| Manage merge requests | `api` |
| Admin operations | `api`, `sudo` |

### URL Encoding Guide

When constructing API URLs, properly encode special characters:

| Character | Encoded |
|-----------|---------|
| `/` | `%2F` |
| `?` | `%3F` |
| `=` | `%3D` |
| `&` | `%26` |
| ` ` (space) | `%20` |

Example:
```
dev_infra/migration/file.py → dev_infra%2Fmigration%2Ffile.py
```