# Token Testing Results - 2026-07-29

## Summary

This document captures the API token testing results from the July 29, 2026 session, including specific findings for GitLab, GitHub, and Infomaniak tokens.

## GitLab AK Token (Akretion Instance)

**Token**: `GITLAB_AK_TOKEN`
**URL**: `https://gitlab.akretion.com`
**Owner**: Sebastien Maurines (sebastien.maurines)
**Email**: sebastien.maurines@akretion.com
**User ID**: 238
**Scope**: `ai_workflows mcp mcp api read_api`

### Test Results

✅ **Working Endpoints**:
- `GET /api/v4/user` - User information
- `GET /api/v4/projects?membership=true` - Project listing
- `GET /api/v4/groups` - Group listing
- `GET /api/v4/projects/:id/repository/tree` - Repository browsing
- `GET /api/v4/projects/:id/merge_requests` - Merge request reading

❌ **Failed Operations**:
- `POST /api/v4/projects/:id/issues` - Issue creation (insufficient_scope)

### Accessible Resources

**Projects**:
- fnfempe [akretion/fnfempe] (ID: 505)
- fnfe [akretion/fnfe] (ID: 496)

**Groups**:
- akretion [akretion] (ID: 2)

### Permission Analysis

**Read Access**: ✅ Full read access to projects, repositories, merge requests, and groups
**Write Access**: ❌ None (read-only token with `read_api` scope)

## GitLab.com Token

**Token**: `GITLAB_COM_TOKEN`
**URL**: `https://gitlab.com`
**Owner**: Sebastien MV (SebastienMV)
**Email**: smv@erk.coach
**User ID**: 34874198
**Scope**: `ai_workflows mcp mcp api read_api`

### Test Results

✅ **Working Endpoints**:
- `GET /api/v4/user` - User information
- `GET /api/v4/projects?membership=true` - Project listing
- `GET /api/v4/groups` - Group listing
- `GET /api/v4/projects/:id/repository/tree` - Repository browsing

❌ **Failed Operations**:
- `POST /api/v4/projects/:id/issues` - Issue creation (insufficient_scope)

### Accessible Resources

**Projects**:
- 2.second-brain [smv-erk-coding/2.second-brain] (private)
- 2.erk-infra [smv-erk-coding/2.erk-infra] (private)
- 1.erk-flux [smv-erk-coding/1.erk-flux] (private)
- converter_ubl_cii_invoice_xml [smv-erk-edi/converter_ubl_cii_invoice_xml] (private)
- factur-x [smv-erk-edi/factur-x] (private)
- veraPDF-rest [smv-erk-edi/veraPDF-rest] (private)
- phive [smv-erk-edi/phive] (private)
- peppol-bis-invoice-3 [smv-erk-edi/peppol-bis-invoice-3] (private)
- l10n-france [smv-erk-edi/l10n-france] (private)
- odoo-fnfe [fnfe/odoo-fnfe] (private)

**Groups**:
- SMV-ERK-CODING [smv-erk-coding] (private)
- SMV-ERK-EDI [smv-erk-edi] (private)
- fnfe [fnfe] (private)

### Permission Analysis

**Read Access**: ✅ Full read access to projects, repositories, and groups
**Write Access**: ❌ None (read-only token with `read_api` scope)

## GitHub Token

**Token**: `GITHUB_TOKEN`
**Status**: ❌ Not found in environment variables

### Search Results

- Checked environment variables: No GitHub token found
- Checked GitHub CLI: Not installed
- Checked Hermes configuration: No GitHub token references
- Checked common locations: No GitHub-related files found

### Recommendation

If GitHub token testing is needed, the token should be:
1. Added to environment variables
2. Stored in `.env` file
3. Configured via GitHub CLI (`gh auth login`)

## Infomaniak Token

**Token**: `INFOMANIAK_TOKEN`
**Status**: ❌ Problematic - API endpoints not found

### Test Results

❌ **Failed Endpoints**:
- `GET /2/user` - 404 (Method not found)
- `GET /2/mail` - 404 (Method not found)
- `GET /1/ai` - missing_ai_tools_scope

### Error Analysis

**Error Types**:
- `method_not_found`: API endpoints don't exist or have changed
- `missing_ai_tools_scope`: Token lacks required AI scope
- `404`: Page not found errors

### Troubleshooting Steps

1. **Verify token in Infomaniak dashboard**: Check expiration and scopes
2. **Consult current API documentation**: https://developer.infomaniak.com
3. **Check API version**: May need different version (v1 vs v2 vs v3)
4. **Regenerate token**: With proper scopes including `ai_tools`
5. **Contact Infomaniak support**: For current API endpoint information

## Comparison Table

| Token | Platform | Status | Read Access | Write Access | Scope |
|-------|----------|--------|-------------|--------------|-------|
| `GITLAB_AK_TOKEN` | Akretion GitLab | ✅ Working | ✅ Full | ❌ None | `read_api` |
| `GITLAB_COM_TOKEN` | GitLab.com | ✅ Working | ✅ Full | ❌ None | `read_api` |
| `GITHUB_TOKEN` | GitHub.com | ❌ Missing | - | - | - |
| `INFOMANIAK_TOKEN` | Infomaniak | ❌ Problematic | ❌ None | ❌ None | Unknown |

## Key Findings

1. **GitLab tokens are working correctly** with read-only access as expected
2. **Both GitLab tokens have identical scopes** (`ai_workflows mcp read_api`)
3. **GitHub token is missing** from environment variables
4. **Infomaniak token has issues** - likely expired, wrong scope, or API changes
5. **All working tokens are read-only** - appropriate for AI automation

## Recommendations

### For GitLab Tokens
- ✅ Continue using current tokens for read operations
- ⚠️ If write access needed, regenerate with additional scopes
- 🔄 Rotate tokens every 3-6 months per security best practices

### For GitHub Token
- ➕ Add GitHub token to environment if GitHub access needed
- 📚 Use `gh auth login` for easy GitHub CLI setup
- 🔐 Store token securely in environment variables

### For Infomaniak Token
- 🔧 Regenerate token with proper scopes (including `ai_tools`)
- 📖 Consult current Infomaniak API documentation
- 📞 Contact Infomaniak support if API endpoints unclear
- ⚠️ Verify token hasn't expired in Infomaniak dashboard

## Testing Commands Used

### GitLab Testing
```bash
# User info
curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/user" | jq .

# Projects
curl -s -H "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/projects?membership=true" | jq .

# Write test
curl -s -X POST -H "PRIVATE-TOKEN: $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Test"}' \
  "https://gitlab.com/api/v4/projects/<id>/issues"
```

### Infomaniak Testing
```bash
# User info (v2)
curl -s -X GET "https://api.infomaniak.com/2/user" -H "Authorization: Bearer $INFOMANIAK_TOKEN"

# AI endpoint
curl -s -X GET "https://api.infomaniak.com/1/ai" -H "Authorization: Bearer $INFOMANIAK_TOKEN"
```

## Lessons Learned

1. **Standardized testing approach works well** for multiple platforms
2. **Read-only tokens are sufficient** for AI automation tasks
3. **API documentation is crucial** for troubleshooting
4. **Environment variable management** is key for token access
5. **Clear, structured output** is preferred for reporting results

This reference document provides a template for future token testing sessions and captures the specific findings from this analysis.