---
name: api-token-management
description: Test and validate API tokens for various platforms.
tags: [api, tokens, authentication, testing, validation]
version: 1.0.0
---

# API Token Management

## Overview

This skill provides comprehensive guidance for testing, validating, and managing API tokens across various platforms including GitLab, GitHub, Infomaniak, and other services. It includes standardized testing procedures, error handling, and permission analysis.

## Table of Contents

1. [General Token Testing Procedure](#general-token-testing-procedure)
2. [GitLab Token Testing](#gitlab-token-testing)
3. [GitHub Token Testing](#github-token-testing)
4. [Infomaniak Token Testing](#infomaniak-token-testing)
5. [Token Permission Analysis](#token-permission-analysis)
6. [Common Issues and Solutions](#common-issues-and-solutions)
7. [Best Practices](#best-practices)

## General Token Testing Procedure

### Standard Testing Approach

1. **Verify token existence**: Check if token variable exists in environment
2. **Test basic connectivity**: Make a simple API call to verify token works
3. **Test specific endpoints**: Validate access to required resources
4. **Test write permissions**: Attempt create/update operations if needed
5. **Analyze scope**: Determine what the token can and cannot access

### Communication Style

**Preferred approach based on user feedback:**
- Be efficient and direct
- Avoid excessive verbosity
- Provide clear, actionable information
- Focus on results rather than detailed process narration
- Use structured output (tables, bullet points) for clarity

## GitLab Token Testing

### Testing Procedure

```bash
# 1. Check token exists
env | grep GITLAB_TOKEN

# 2. Test user information (basic connectivity)
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/user" | jq .

# 3. Test project access
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects?membership=true&per_page=5" | jq .

# 4. Test group access
curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups?per_page=5" | jq .

# 5. Test write permissions (issue creation)
curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Test API Issue","description":"Testing write permissions"}' \
  "https://gitlab.com/api/v4/projects/<project_id>/issues"
```

### Expected Results

**Success**: Returns user/project/group data in JSON format
**Failure**: Returns error with specific scope information

### Scope Analysis

Check the `scope` field in error responses to understand token limitations:
- `read_api`: Read-only access
- `ai_workflows`: AI tool integration
- `mcp`: Model Context Protocol access

## GitHub Token Testing

### Testing Procedure

```bash
# 1. Check token exists
env | grep GITHUB_TOKEN

# 2. Test user information
curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/user" | jq .

# 3. Test repository access
curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/user/repos?per_page=5" | jq .

# 4. Test write permissions
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Test Issue","body":"Testing write permissions"}' \
  "https://api.github.com/repos/<owner>/<repo>/issues"
```

## Infomaniak Token Testing

### Current API Endpoints

```bash
# User information (v2 API)
curl -s -X GET "https://api.infomaniak.com/2/user" -H "Authorization: Bearer $INFOMANIAK_TOKEN"

# Mail services
curl -s -X GET "https://api.infomaniak.com/2/mail" -H "Authorization: Bearer $INFOMANIAK_TOKEN"

# AI tools endpoint
curl -s -X GET "https://api.infomaniak.com/1/ai" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
```

### Known Issues

- **404 errors**: API endpoints may have changed or been deprecated
- **missing_ai_tools_scope**: Token lacks required AI scope
- **method_not_found**: Endpoint doesn't exist or API version changed
- **HTML error pages**: Some errors return full HTML pages instead of JSON

### Common Error Patterns

#### Scope-Specific Errors

```json
{
  "result": "error",
  "error": {
    "code": "invalid_scope_token",
    "description": "missing_ai_tools_scope"
  }
}
```

#### Endpoint Not Found Errors

```json
{
  "result": "error",
  "error": {
    "code": "method_not_found",
    "description": "Method not found"
  }
}
```

### Troubleshooting

1. **Check token in Infomaniak dashboard**: Verify expiration and scopes
   - URL: https://manager.infomaniak.com
   - Navigate to API token section
   - Verify token has required scopes: read, calendar, kchat, kmeet

2. **Consult current API documentation**: https://developer.infomaniak.com
   - Check "Getting Started" section for current base URLs
   - Verify API version compatibility (v1 vs v2)
   - Look for endpoint deprecation notices

3. **Regenerate token**: With proper scopes if needed
   ```
   Required scopes: read, calendar, kchat, kmeet
   Optional scopes: ai_tools (only if AI access needed)
   ```

4. **Test multiple endpoint variations**:
   ```bash
   ENDPOINTS=(
       "https://api.infomaniak.com/2/user"
       "https://api.infomaniak.com/1/user"
       "https://api.infomaniak.com/v4/user"
       "https://api.infomaniak.com/api/v2/user"
   )
   
   for ENDPOINT in "${ENDPOINTS[@]}"; do
       echo "Testing: $ENDPOINT"
       curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "$ENDPOINT" | head -5
       echo "---"
   done
   ```

5. **Contact support**: For API endpoint changes
   - Provide token ID and specific error messages
   - Ask about current API endpoint structure
   - Request verification of token scopes and permissions

### Infomaniak-Specific Testing Script

```bash
#!/bin/bash
# Infomaniak token comprehensive tester

TOKEN="$INFOMANIAK_TOKEN"
if [ -z "$TOKEN" ] || [ "$TOKEN" = "***" ]; then
    echo "❌ INFOMANIAK_TOKEN not found or redacted"
    exit 1
fi

echo "=== INFOMANIAK TOKEN TEST ==="
echo "Token present: ✓"
echo ""

# Test various known endpoints
TESTS=(
    "2/user:User Information (v2)"
    "2/mail:Mail Services (v2)"
    "1/ai:AI Tools (v1)"
    "1/kmeet:kMeet (v1)"
    "1/kchat:kChat (v1)"
)

for TEST in "${TESTS[@]}"; do
    ENDPOINT="${TEST%%:*}"
    DESCRIPTION="${TEST#*:}"
    URL="https://api.infomaniak.com/$ENDPOINT"
    
    echo "Testing $DESCRIPTION:"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$URL")
    
    case "$RESPONSE" in
        "200") echo "  ✓ Success (200)" ;;
        "404") echo "  ❌ Not Found (404)" ;;
        "403") echo "  ❌ Forbidden (403)" ;;
        "401") echo "  ❌ Unauthorized (401)" ;;
        *) echo "  ⚠ Unexpected response: $RESPONSE" ;;
    esac
done

echo ""
echo "=== RECOMMENDATIONS ==="
echo "If most tests failed:"
echo "  1. Check token in Infomaniak dashboard"
echo "  2. Regenerate token with proper scopes"
echo "  3. Consult current API documentation"
echo "  4. Contact Infomaniak support"
```

### Reference Documentation

For detailed testing results and specific error patterns, see:
- [Infomaniak Token Testing - 2026-07-29](references/infomaniak-token-testing-20260729.md)

## Token Permission Analysis

### Comprehensive Analysis Template

```bash
echo "=== TOKEN ANALYSIS REPORT ==="
echo "Token: $TOKEN_NAME"
echo "Owner: $(curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/user" | jq -r '.username')"
echo "Scope: $(curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/user" | jq -r '.scope // "unknown"')"
echo ""
echo "=== ACCESSIBLE RESOURCES ==="
echo "Projects:"
curl -s -H "Authorization: Bearer $TOKEN" "https://api.example.com/projects?membership=true" | jq -r '.[] | "  - \(.name) [\(.path)]"'
echo ""
echo "=== PERMISSION SUMMARY ==="
echo "✓ Read access to: [list resources]"
echo "✗ Write access to: [list limitations]"
```

### Permission Matrix

| Platform | Read Access | Write Access | Common Scopes |
|----------|-------------|--------------|---------------|
| GitLab | Projects, repos, issues, MRs | Issue/MR creation, repo writes | `read_api`, `write_repository`, `api` |
| GitHub | User info, repos, issues | Issue/PR creation, repo writes | `repo`, `read:org`, `write:discussion` |
| Infomaniak | Mail services, user info | Service management | `ai_tools`, `mail_management` |

## Common Issues and Solutions

### Issue: Token not found in environment

**Solution**:
```bash
# Check all environment variables
env | grep -i token

# Check specific files
cat ~/.bashrc | grep -i token
cat ~/.zshrc | grep -i token
```

### Issue: API endpoint not found (404)

**Solutions**:
1. Verify API version (v1 vs v2 vs v3)
2. Check for deprecated endpoints
3. Consult current API documentation
4. Test with different base URLs

### Issue: Insufficient scope

**Solutions**:
1. Regenerate token with required scopes
2. Check scope requirements in API docs
3. Use appropriate token type (personal vs service account)

### Issue: Rate limiting

**Solutions**:
1. Check rate limit headers
2. Implement exponential backoff
3. Cache responses when appropriate
4. Use pagination for large datasets

## Best Practices

### Token Management

1. **Never commit tokens** to version control
2. **Use environment variables** for token storage
3. **Rotate tokens regularly** (every 3-6 months)
4. **Limit token scopes** to minimum required
5. **Use short-lived tokens** for CI/CD pipelines

### Testing Procedure

1. **Start with read-only tests** before attempting writes
2. **Test on non-critical resources** first
3. **Use pagination** for large datasets
4. **Handle errors gracefully** in scripts
5. **Document token capabilities** for future reference

### Security

1. **Audit token usage** regularly
2. **Revoke unused tokens** immediately
3. **Use IP restrictions** when possible
4. **Monitor for anomalies** in token usage
5. **Educate team members** on token security

## Usage Examples

### Example: Comprehensive GitLab Token Test

```bash
#!/bin/bash
# Comprehensive GitLab token testing script

TOKEN="$GITLAB_TOKEN"
API_URL="https://gitlab.com/api/v4"

echo "=== GITLAB TOKEN TEST ==="
echo ""

# Test 1: User info
echo "1. Testing user information:"
curl -s -H "PRIVATE-TOKEN: $TOKEN" "$API_URL/user" | jq '{username, email, id}'
echo ""

# Test 2: Project access
echo "2. Testing project access:"
curl -s -H "PRIVATE-TOKEN: $TOKEN" "$API_URL/projects?membership=true&per_page=3" | jq '.[] | {name, path_with_namespace}'
echo ""

# Test 3: Write permissions
echo "3. Testing write permissions:"
TEST_PROJECT="$(curl -s -H "PRIVATE-TOKEN: $TOKEN" "$API_URL/projects?membership=true&per_page=1" | jq -r '.[0].id')"
if [ "$TEST_PROJECT" != "null" ] && [ "$TEST_PROJECT" != "" ]; then
    curl -s -X POST -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
        -d '{"title":"Token Test Issue","description":"Testing write permissions"}' \
        "$API_URL/projects/$TEST_PROJECT/issues" | jq '{status: (.iid != null | tostring), error: .error // "none"}'
else
    echo "No projects found for write test"
fi
```

### Example: Token Validation Script

```bash
#!/bin/bash
# Validate multiple tokens

declare -A TOKENS=(
    ["GITLAB_COM"]="$GITLAB_COM_TOKEN"
    ["GITLAB_AK"]="$GITLAB_AK_TOKEN"
    ["INFOMANIAK"]="$INFOMANIAK_TOKEN"
)

for PLATFORM in "${!TOKENS[@]}"; do
    TOKEN="${TOKENS[$PLATFORM]}"
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "***" ]; then
        echo "❌ $PLATFORM: Token not found"
        continue
    fi
    
    echo "✓ $PLATFORM: Token exists"
    
    # Platform-specific testing would go here
    case "$PLATFORM" in
        "GITLAB_COM")
            curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/user" > /dev/null
            [ $? -eq 0 ] && echo "  ✓ Basic connectivity works" || echo "  ✗ Connectivity failed"
            ;;
        "INFOMANIAK")
            curl -s -H "Authorization: Bearer $TOKEN" "https://api.infomaniak.com/2/user" > /dev/null
            [ $? -eq 0 ] && echo "  ✓ Basic connectivity works" || echo "  ✗ Connectivity failed"
            ;;
    esac
done
```

## Triggers

This skill is invoked when testing or managing API tokens for:
- GitLab (both .com and self-hosted instances)
- GitHub
- Infomaniak
- Other platforms requiring token-based authentication
- Token validation and permission analysis
- API connectivity testing
- Automation script development involving tokens

## References

- [GitLab API Documentation](https://docs.gitlab.com/ee/api/)
- [GitHub API Documentation](https://docs.github.com/en/rest)
- [Infomaniak Developer Portal](https://developer.infomaniak.com)
- [OAuth 2.0 Token Best Practices](https://datatracker.ietf.org/doc/html/rfc6819)

*Use this skill for systematic API token testing, validation, and management across platforms.*