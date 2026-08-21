# Akretion GitLab Repositories

## Overview

This document describes the repositories available on Akretion's self-hosted GitLab instance and their access patterns.

## Instance Information

- **URL**: https://gitlab.akretion.com
- **API Base**: https://gitlab.akretion.com/api/v4/
- **Authentication**: Personal Access Tokens
- **Token Variable**: `GITLAB_AK_TOKEN`

## Available Repositories

### 1. fnfe

**Full Path**: akretion/fnfe
**Description**: Main infrastructure and Odoo repository
**Access**: Full access with `GITLAB_AK_TOKEN`

#### Structure

```
fnfe/
├── app/
│   ├── ai-tools/
│   │   ├── plantuml-cli/
│   │   └── marp-cli/
│   └── odoo/
├── platform/
│   ├── iam/
│   └── passbolt/
├── provisioning/
│   ├── Cluster-Install_README.md
│   └── dns-mail/
└── README.md
```

#### Common Operations

```bash
# List projects
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true"

# Get project info
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe"

# List repository tree
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe/repository/tree"

# Get specific file
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/akretion%2Ffnfe/repository/files/platform%2Fiam%2FREADME.md/raw?ref=main"
```

### 2. fnfempe

**Full Path**: akretion/fnfempe
**Description**: Additional Odoo and migration components
**Access**: Full access with `GITLAB_AK_TOKEN`

#### Structure

```
fnfempe/
├── migrations/
│   ├── odoo-14-to-16/
│   └── odoo-16-to-18/
├── modules/
│   └── custom/
└── README.md
```

## Access Patterns

### Authentication

```bash
# Set token in environment
export GITLAB_AK_TOKEN="your_token_here"

# Test token
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/user"
```

### Common Workflows

#### 1. List All Projects

```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true&per_page=100" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Akretion projects: {len(data)}')
for p in data:
    print(f'- {p[\"name\"]:20}  {p[\"path_with_namespace\"]}')"
```

#### 2. Get Repository Structure

```bash
PROJECT="akretion/fnfe"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/repository/tree?recursive=false" \
  | python3 -c "
import sys, json
for item in json.load(sys.stdin):
    print(f'{item[\"type\"]:10}  {item[\"name\"]}')"
```

#### 3. Search for Files

```bash
PROJECT="akretion/fnfe"
PATH="platform/iam"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/repository/tree?path=$PATH" \
  | python3 -c "
import sys, json
for item in json.load(sys.stdin):
    if item['type'] == 'blob':
        print(f'FILE: {item[\"path\"]}')
    elif item['type'] == 'tree':
        print(f'DIR:  {item[\"path\"]}/')"
```

#### 4. Get File Contents

```bash
PROJECT="akretion/fnfe"
FILE_PATH="platform/iam/README.md"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/repository/files/$FILE_PATH/raw?ref=main"
```

## Branch Management

### List Branches

```bash
PROJECT="akretion/fnfe"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/repository/branches" \
  | python3 -c "
import sys, json
for b in json.load(sys.stdin):
    print(f'{b[\"name\"]:20}  {b[\"commit\"][\"id\"][:8]}  {b[\"protected\"]}')"
```

### Create Branch

```bash
PROJECT="akretion/fnfe"
curl -s -X POST --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/repository/branches" \
  -d "branch=feature/new-feature" \
  -d "ref=main"
```

## Issue Management

### List Issues

```bash
PROJECT="akretion/fnfe"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/issues?state=opened&per_page=50" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin):
    print(f'#{i[\"iid\"]}: {i[\"title\"]}')"
```

### Create Issue

```bash
PROJECT="akretion/fnfe"
curl -s -X POST --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/issues" \
  -d "title=Update documentation" \
  -d "description=Update README with new deployment instructions" \
  -d "labels=documentation"
```

## Merge Requests

### List Merge Requests

```bash
PROJECT="akretion/fnfe"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/merge_requests?state=opened&per_page=20" \
  | python3 -c "
import sys, json
for mr in json.load(sys.stdin):
    print(f'!{mr[\"iid\"]}: {mr[\"title\"]} ({mr[\"source_branch\"]} -> {mr[\"target_branch\"]})')"
```

### Create Merge Request

```bash
PROJECT="akretion/fnfe"
curl -s -X POST --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/merge_requests" \
  -d "source_branch=feature/new-feature" \
  -d "target_branch=main" \
  -d "title=Add new feature" \
  -d "description=Implements new feature X with tests" \
  -d "labels=enhancement"
```

## CI/CD Pipelines

### List Pipelines

```bash
PROJECT="akretion/fnfe"
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/pipelines?per_page=10" \
  | python3 -c "
import sys, json
for p in json.load(sys.stdin):
    print(f'#{p[\"id\"]}: {p[\"status\"]} ({p[\"ref\"]})')"
```

### Trigger Pipeline

```bash
PROJECT="akretion/fnfe"
curl -s -X POST --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/$PROJECT/pipeline" \
  -d "ref=main"
```

## Best Practices

### 1. Use Environment Variables

```bash
# Set token once
export GITLAB_AK_TOKEN="your_token_here"

# Use in all commands
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" ...
```

### 2. Handle Pagination

```bash
# Get all projects (handle pagination)
PAGE=1
while true; do
  data=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
    "https://gitlab.akretion.com/api/v4/projects?membership=true&page=$PAGE&per_page=100")
  
  if [ "$data" = "[]" ]; then
    break
  fi
  
  echo "$data" | python3 -c "
import sys, json
for p in json.load(sys.stdin):
    print(f'- {p[\"name\"]}')"
  
  PAGE=$((PAGE + 1))
done
```

### 3. Use Pagination for Large Results

```bash
# Always use per_page=100 (maximum)
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?per_page=100"
```

### 4. Cache Results When Possible

```bash
# Cache project list
PROJECTS=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true&per_page=100")

# Use cached results
echo "$PROJECTS" | python3 -c "...
```

### 5. Use Python for Complex Processing

```bash
# Complex processing with Python
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true&per_page=100" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)

# Process data
for project in data:
    print(f'Project: {project[\"name\"]}')
    print(f'  ID: {project[\"id\"]}')
    print(f'  Path: {project[\"path_with_namespace\"]}')
    print(f'  URL: {project[\"web_url\"]}')
    print()"
```

## Common Issues

### 401 Unauthorized

**Cause**: Invalid or expired token

**Solution**:
```bash
# Verify token
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/user"

# Create new token if needed
# Visit: https://gitlab.akretion.com/-/profile/personal_access_tokens
```

### 404 Not Found

**Cause**: Project doesn't exist or wrong path

**Solution**:
```bash
# List accessible projects
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects?membership=true"

# Verify project path
```

### 403 Forbidden

**Cause**: Insufficient permissions

**Solution**:
```bash
# Check your access level
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/projects/PROJECT_ID/members/all?user_id=YOUR_USER_ID"

# Request higher access if needed
```

## Rate Limits

- **Authenticated**: 10,000 requests per minute
- **Unauthenticated**: 600 requests per minute (shared IP)

**Check rate limit**:
```bash
curl -s --header "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" \
  "https://gitlab.akretion.com/api/v4/user" \
  | grep -i rate
```

## References

- [Akretion GitLab Instance](https://gitlab.akretion.com)
- [GitLab API Documentation](https://docs.gitlab.com/ee/api/)
- [Personal Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)

## Updates

### 2026-08-12

- Added detailed repository structures
- Added common workflow examples
- Added best practices section
- Added troubleshooting guide

### 2026-07-26

- Initial documentation
- Basic repository listing
- Common operations

## Status

**Current**: Fully functional with `GITLAB_AK_TOKEN`. Use REST API for reliable operations. MCP tools may have stability issues - prefer direct API calls.