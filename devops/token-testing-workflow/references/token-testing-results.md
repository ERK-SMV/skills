# Token Testing Results - 2026-07-29

## Summary

This document captures the results of token testing performed on 2026-07-29 for GitLab and Infomaniak services.

## GitLab Tokens

### GITLAB_AK_TOKEN (Akretion Instance)

**Status**: ✅ Working

**Token Details**:
- **Owner**: Sebastien Maurines (sebastien.maurines)
- **Email**: sebastien.maurines@akretion.com
- **User ID**: 238
- **Scope**: `ai_workflows mcp mcp api read_api`

**Accessible Resources**:
- **Projects**: fnfempe, fnfe
- **Groups**: akretion

**Permissions**:
- ✅ Read access to user profile
- ✅ Read access to projects and repositories
- ✅ Read access to merge requests
- ✅ Read access to issues
- ❌ Write access (read-only token)

**API Base URL**: `https://gitlab.akretion.com/api/v4/`

### GITLAB_COM_TOKEN (GitLab.com Instance)

**Status**: ✅ Working

**Token Details**:
- **Owner**: Sebastien MV (SebastienMV)
- **Email**: smv@erk.coach
- **User ID**: 34874198
- **Scope**: `ai_workflows mcp mcp api read_api`

**Accessible Resources**:
- **Projects**: 10 projects across 3 groups
  - SMV-ERK-CODING: 2.second-brain, 2.erk-infra, 1.erk-flux
  - SMV-ERK-EDI: converter_ubl_cii_invoice_xml, factur-x, veraPDF-rest, phive, peppol-bis-invoice-3, l10n-france
  - fnfe: odoo-fnfe
- **Groups**: SMV-ERK-CODING, SMV-ERK-EDI, fnfe

**Permissions**:
- ✅ Read access to user profile
- ✅ Read access to projects and repositories
- ✅ Read access to groups
- ❌ Write access (read-only token)

**API Base URL**: `https://gitlab.com/api/v4/`

## Infomaniak Token

**Status**: ❌ Not Working

**Token Variable**: `INFOMANIAK_TOKEN`

**Tested Endpoints**:
- `https://api.infomaniak.com/api/v4/users` → 404 Not Found
- `https://api.infomaniak.com/v4/users` → 404 Not Found
- `https://api.infomaniak.com/1/ai` → missing_ai_tools_scope
- `https://api.infomaniak.com/1/kmeet` → 404 Not Found
- `https://api.infomaniak.com/1/kchat` → 404 Not Found
- `https://api.infomaniak.com/1/calendar` → 404 Not Found

**Error Analysis**:
- All endpoints return 404 errors
- AI endpoint specifically reports missing scope
- Token may be expired or invalid
- API endpoints may have changed

**Required Scopes**: read, calendar, kchat, kmeet

**Recommendations**:
1. Check token in Infomaniak dashboard: https://manager.infomaniak.com
2. Regenerate token with proper scopes
3. Verify current API documentation
4. Contact Infomaniak support if issues persist

## Tool Testing Results

### PlantUML Server

**Status**: ❌ Not Accessible

**URL**: `http://plantuml-service.ai-tools.svc.cluster.local`

**Error**: 404 Not Found

**Analysis**: Service may not be running or URL may be incorrect

### Marp CLI

**Status**: ❌ Not Installed

**Requirements**: Node.js and npm

**Installation Command**:
```bash
apt-get install nodejs npm && npm install -g @marp-team/marp-cli
```

## Testing Commands

### GitLab Token Testing

```bash
# Test Akretion GitLab token
curl -s -H "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" "https://gitlab.akretion.com/api/v4/user" | jq .

# Test GitLab.com token
curl -s -H "PRIVATE-TOKEN: $GITLAB_COM_TOKEN" "https://gitlab.com/api/v4/user" | jq .

# List accessible projects (Akretion)
curl -s -H "PRIVATE-TOKEN: $GITLAB_AK_TOKEN" "https://gitlab.akretion.com/api/v4/projects?membership=true" | jq .

# List accessible projects (GitLab.com)
curl -s -H "PRIVATE-TOKEN: $GITLAB_COM_TOKEN" "https://gitlab.com/api/v4/projects?membership=true" | jq .
```

### Infomaniak Token Testing

```bash
# Test users endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/api/v4/users"

# Test calendar endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/1/calendar"

# Test kMeet endpoint
curl -s -H "Authorization: Bearer $INFOMANIAK_TOKEN" "https://api.infomaniak.com/1/kmeet"
```

## Summary

- **GitLab Tokens**: Both working with read-only access
- **Infomaniak Token**: Not working, needs regeneration with proper scopes
- **PlantUML Server**: Not accessible (404 error)
- **Marp CLI**: Not installed (Node.js required)

## Recommendations

1. **Infomaniak Token**: Regenerate with scopes: read, calendar, kchat, kmeet
2. **PlantUML Server**: Check Kubernetes service status and URL
3. **Marp CLI**: Install Node.js and npm, then install Marp CLI globally
4. **Token Management**: Store tokens securely and document their scopes
5. **API Testing**: Use curl with proper headers for token validation