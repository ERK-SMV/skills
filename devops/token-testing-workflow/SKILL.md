---
name: token-testing-workflow
description: "Test API tokens for GitLab and Infomaniak platforms."
version: 1.0.0
author: Hermes Agent
tags: [api, tokens, testing, gitlab, infomaniak, troubleshooting]
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [api, tokens, testing, gitlab, infomaniak, troubleshooting]
    related_skills: [infra-k8s-manager, github-auth]
---

# Token Testing Workflow

Comprehensive guide for testing API tokens across various platforms with troubleshooting and validation techniques.

## Overview

This skill provides a systematic approach to testing API tokens, validating their scopes, and troubleshooting common issues. It includes specific workflows for GitLab, Infomaniak, and other platforms.

## Table of Contents

1. [General Token Testing Principles](#general-token-testing-principles)
2. [GitLab Token Testing](#gitlab-token-testing)
3. [Infomaniak Token Testing](#infomaniak-token-testing)
4. [Common Issues and Solutions](#common-issues-and-solutions)
5. [Token Testing Commands](#token-testing-commands)
6. [Troubleshooting Guide](#troubleshooting-guide)

## General Token Testing Principles

### Best Practices

1. **Start with User Info**: Always test the user endpoint first to validate token authenticity
2. **Check Scopes**: Verify token has required scopes for intended operations
3. **Test Read Operations**: Validate read access before attempting write operations
4. **Use Proper Headers**: Ensure correct Authorization headers are used
5. **Handle Errors Gracefully**: Parse error responses for specific scope or permission issues

### Common Authorization Headers

```bash
# GitLab
-H "PRIVATE-TOKEN: $TOKEN"

# Infomaniak
-H "Authorization: Bearer $TOKEN"

# Generic OAuth2
-H "Authorization: Bearer $TOKEN"
```

## GitLab Token Testing

### Testing Workflow

1. **Validate Token Authenticity**
   ```bash
   curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/user"
   ```

2. **Check Accessible Projects**
   ```bash
   curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects?membership=true"
   ```

3. **Test Repository Access**
   ```bash
   curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/OWNER%2FREPO/repository/tree"
   ```

4. **Test Write Permissions**
   ```bash
   curl -s -X POST -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
     -d '{"title":"Test Issue","description":"Testing write permissions"}' \
     "https://gitlab.com/api/v4/projects/OWNER%2FREPO/issues"
   ```

### Expected Responses

**Working Token**:
```json
{
  "id": 12345,
  "username": "user",
  "name": "User Name",
  "state": "active",
  ...
}
```

**Read-Only Token (Write Attempt)**:
```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "ai_workflows mcp mcp api read_api"
}
```

**Invalid Token**:
```json
{
  "message": "401 Unauthorized"
}
```

## Infomaniak Token Testing

### Testing Workflow

1. **Test User Endpoint**
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" "https://api.infomaniak.com/api/v4/users"
   ```

2. **Test Calendar Endpoint**
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" "https://api.infomaniak.com/1/calendar"
   ```

3. **Test kMeet Endpoint**
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" "https://api.infomaniak.com/1/kmeet"
   ```

4. **Test kChat Endpoint**
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" "https://api.infomaniak.com/1/kchat"
   ```

### Common Infomaniak Errors

**Missing Scope**:
```json
{
  "result": "error",
  "error": {
    "code": "invalid_scope_token",
    "description": "missing_ai_tools_scope"
  }
}
```

**Endpoint Not Found**:
```json
{
  "result": "error",
  "error": {
    "code": "method_not_found",
    "description": "Method not found"
  }
}
```

**404 HTML Page**: Indicates endpoint doesn't exist or token is invalid

## Common Issues and Solutions

### Issue: Token Returns 404 Errors

**Possible Causes**:
- Token is expired
- API endpoint has changed
- Token lacks required scopes
- Service is temporarily unavailable

**Solutions**:
1. Regenerate token with proper scopes
2. Check API documentation for current endpoints
3. Verify service status page
4. Contact platform support

### Issue: Insufficient Scope Errors

**Possible Causes**:
- Token was created with read-only scope
- Token lacks specific API permissions
- Token scopes were modified after creation

**Solutions**:
1. Regenerate token with required scopes
2. Check token creation settings
3. Verify scope requirements in API docs

### Issue: Token Works for Read but Not Write

**Possible Causes**:
- Token has read-only scope
- User lacks write permissions on resource
- Resource has write restrictions

**Solutions**:
1. Regenerate token with write scopes
2. Check user permissions on resource
3. Verify resource write restrictions

## Token Testing Commands

### GitLab Commands

```bash
# Test token authenticity (GitLab.com)
curl -s -H "PRIVATE-TOKEN: $GITLAB_COM_TOKEN" "https://gitlab.com/api/v4/user" | jq .

# Test token authenticity (Akretion)
curl -s -H "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" "https://gitlab.akretion.com/api/v4/user" | jq .

# List accessible projects
curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects?membership=true" | jq .

# Test repository access
curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/OWNER%2FREPO/repository/tree?per_page=10" | jq .

# Test merge request access
curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects/OWNER%2FREPO/merge_requests?state=all&per_page=5" | jq .

# Test write permissions (issue creation)
curl -s -X POST -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Test API Issue","description":"Testing write permissions via API"}' \
  "https://gitlab.com/api/v4/projects/OWNER%2FREPO/issues"
```

### Infomaniak Commands

```bash
# Test users endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/api/v4/users"

# Test calendar endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/1/calendar"

# Test kMeet endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/1/kmeet"

# Test kChat endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/1/kchat"

# Test AI endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/1/ai"
```

## Troubleshooting Guide

### Step 1: Verify Token Existence

```bash
env | grep TOKEN
echo "Token length: ${#TOKEN}"
```

### Step 2: Test Basic Connectivity

```bash
# Test without token to check if endpoint exists
curl -s "https://api.example.com/endpoint" | head -5

# Test with token
curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/endpoint" | head -5
```

### Step 3: Check Error Responses

```bash
# Get full error response
curl -s -v -H "Authorization: Bearer $TOKEN" "https://api.example.com/endpoint"
```

### Step 4: Validate Token Scopes

```bash
# For platforms that expose token info
curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/token/info"
```

### Step 5: Check API Status

```bash
# Check platform status page
curl -s "https://status.example.com/"
```

## Token Management Best Practices

### Secure Storage

- Use environment variables for tokens
- Never commit tokens to version control
- Use secret management tools (Passbolt, Vault, etc.)
- Rotate tokens regularly

### Documentation

- Document token scopes and purposes
- Track token expiration dates
- Note which services use each token
- Document token creation process

### Testing

- Test tokens immediately after creation
- Validate all required scopes
- Test both read and write operations
- Document testing results

## Reference: Token Testing Results

For specific token testing results from 2026-07-29, see:
- GitLab AK Token: Working with read-only access
- GitLab.com Token: Working with read-only access  
- Infomaniak Token: Not working (404 errors, missing scopes)

See the `references/token-testing-results.md` file for detailed results.

## Triggers

This skill is automatically invoked when you ask about:
- API token testing
- Token validation
- Token troubleshooting
- GitLab token testing
- Infomaniak token testing
- Token scope verification
- API authentication issues