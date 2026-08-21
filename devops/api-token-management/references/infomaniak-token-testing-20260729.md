# Infomaniak Token Testing - 2026-07-29

## Overview

This document captures the specific Infomaniak token testing procedures, issues encountered, and solutions identified during the 2026-07-29 testing session.

## Token Information

- **Token Variable**: `INFOMANIAK_TOKEN`
- **Intended Scopes**: Read access, Calendar, kChat, kMeet
- **Testing Date**: 2026-07-29

## Tested Endpoints

### Failed Endpoints (404 Errors)

```bash
# All returned 404 "Method not found" or "Page not found"
curl -s -X GET "https://api.infomaniak.com/api/v4/users" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
curl -s -X GET "https://api.infomaniak.com/v4/users" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
curl -s -X GET "https://api.infomaniak.com/1/kmeet" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
curl -s -X GET "https://api.infomaniak.com/1/kchat" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
curl -s -X GET "https://api.infomaniak.com/1/calendar" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
```

### Scope-Specific Failure

```bash
# AI endpoint - confirmed missing scope
curl -s -X GET "https://api.infomaniak.com/1/ai" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
# Response: {"result":"error","error":{"code":"invalid_scope_token","description":"missing_ai_tools_scope"}}
```

## Error Patterns

### 404 Method Not Found

```json
{
  "result": "error",
  "error": {
    "code": "method_not_found",
    "description": "Method not found"
  }
}
```

### 404 Page Not Found (HTML)

When endpoints don't exist, Infomaniak returns a full HTML error page with:
- Title: "Page introuvable..." (Page not found...)
- Description: "La page que vous recherchez a été déplacée, effacée, renommée, ou n'a peut-être jamais existé."
- Status: 404

### Missing Scope Error

```json
{
  "result": "error",
  "error": {
    "code": "invalid_scope_token",
    "description": "missing_ai_tools_scope"
  }
}
```

## Root Cause Analysis

### Possible Issues Identified

1. **Token Expiration**: Token may have expired
2. **Incorrect Scopes**: Token lacks required scopes despite configuration
3. **API Version Mismatch**: Using wrong API version (v1 vs v2)
4. **Endpoint Changes**: API endpoints may have been deprecated or moved
5. **Token Type Issue**: May need service-specific token vs user token

### Verification Steps

1. **Check token in Infomaniak dashboard**:
   - URL: https://manager.infomaniak.com
   - Navigate to API token section
   - Verify expiration date and scopes

2. **Consult current API documentation**:
   - Developer portal: https://developer.infomaniak.com
   - Check for API version changes
   - Verify current endpoint URLs

3. **Test with known-working token**:
   - Compare with other working Infomaniak tokens
   - Test same endpoints with different tokens

## Recommended Solutions

### Immediate Actions

1. **Regenerate token with proper scopes**:
   ```
   Required scopes: read, calendar, kchat, kmeet
   Optional scopes: ai_tools (if needed)
   ```

2. **Verify API version compatibility**:
   - Test both v1 and v2 endpoints
   - Check API changelog for breaking changes

3. **Contact Infomaniak support**:
   - Provide token ID and error details
   - Ask about current API endpoint structure
   - Request API status verification

### Long-term Recommendations

1. **Create token validation script**:
   ```bash
   #!/bin/bash
   # Infomaniak token validator
   
   TOKEN="$INFOMANIAK_TOKEN"
   if [ -z "$TOKEN" ] || [ "$TOKEN" = "***" ]; then
       echo "❌ INFOMANIAK_TOKEN not found in environment"
       exit 1
   fi
   
   echo "Testing Infomaniak token..."
   
   # Test basic connectivity
   RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
       -H "Authorization: Bearer $TOKEN" \
       "https://api.infomaniak.com/2/user")
   
   if [ "$RESPONSE" = "200" ]; then
       echo "✓ Token is valid"
   elif [ "$RESPONSE" = "404" ]; then
       echo "❌ API endpoint not found - may need token regeneration"
   elif [ "$RESPONSE" = "403" ]; then
       echo "❌ Forbidden - token may lack required scopes"
   else
       echo "❌ Unexpected response: $RESPONSE"
   fi
   ```

2. **Document current working endpoints**:
   - Maintain updated list of verified API endpoints
   - Track API version changes
   - Document scope requirements per endpoint

## Troubleshooting Guide

### Step-by-Step Debugging

1. **Verify token existence**:
   ```bash
   env | grep INFOMANIAK_TOKEN
   echo "Token length: ${#INFOMANIAK_TOKEN}"
   ```

2. **Test basic authentication**:
   ```bash
   curl -v -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/"
   ```

3. **Check API status**:
   - Visit: https://infomaniakstatus.com
   - Look for API service alerts

4. **Test with different endpoints**:
   ```bash
   # Try various known endpoints
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

5. **Compare with documentation**:
   - Visit developer portal
   - Check "Getting Started" section
   - Verify base URL and authentication method

## Lessons Learned

1. **Infomaniak API is version-sensitive**: Different versions have different endpoints
2. **Token scopes are strictly enforced**: Missing scopes cause clear error messages
3. **API documentation may lag**: Actual endpoints may differ from docs
4. **HTML error pages**: Some errors return full HTML pages, not JSON
5. **Token regeneration often needed**: Scopes and permissions can be complex

## Future Testing Recommendations

1. **Start with API status check**: Verify service is operational
2. **Test multiple endpoint variations**: Try different versions and paths
3. **Check both JSON and HTML responses**: Handle different error formats
4. **Document working configurations**: Maintain records of successful setups
5. **Implement comprehensive error handling**: Prepare for various response types

## References

- [Infomaniak Developer Portal](https://developer.infomaniak.com)
- [Infomaniak Status Page](https://infomaniakstatus.com)
- [Infomaniak Manager Dashboard](https://manager.infomaniak.com)
- [API Token Management Skill](../SKILL.md)