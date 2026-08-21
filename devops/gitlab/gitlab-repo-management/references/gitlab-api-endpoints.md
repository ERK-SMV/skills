# GitLab API Endpoints Reference

## Base URL

```
https://gitlab.com/api/v4/    # For gitlab.com
https://<your-instance>/api/v4/  # For self-hosted
```

## Authentication

All requests require one of:
- Header: `PRIVATE-TOKEN: <personal_access_token>`
- Header: `Authorization: Bearer <oauth2_token>`

## Projects / Repositories

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/projects` | GET | List all projects user has access to |
| `/projects?owned=true` | GET | List projects owned by user |
| `/projects?membership=true` | GET | List projects user is a member of |
| `/projects?search=<query>` | GET | Search projects by name |
| `/projects/:id` | GET | Get single project |
| `/projects` | POST | Create new project |
| `/projects/:id` | PUT | Update project |
| `/projects/:id` | DELETE | Delete project |

### Query Parameters for Projects

| Parameter | Type | Description |
|-----------|------|-------------|
| `owned` | boolean | Only projects owned by current user |
| `membership` | boolean | Only projects user is a member of |
| `search` | string | Search by name |
| `per_page` | integer | Items per page (max 100) |
| `page` | integer | Page number |
| `order_by` | string | `name`, `path`, `created_at`, `updated_at`, `last_activity_at` |
| `sort` | string | `asc`, `desc` |

## Repository Contents

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/projects/:id/repository/tree` | GET | List directory contents |
| `/projects/:id/repository/tree?path=<path>&recursive=true` | GET | List all files recursively |
| `/projects/:id/repository/files/:path` | GET | Get file contents |
| `/projects/:id/repository/files/:path` | POST | Create/update file |
| `/projects/:id/repository/files/:path` | DELETE | Delete file |

## Branches

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/projects/:id/repository/branches` | GET | List all branches |
| `/projects/:id/repository/branches/:branch` | GET | Get single branch |
| `/projects/:id/repository/branches` | POST | Create branch |
| `/projects/:id/repository/branches/:branch` | DELETE | Delete branch |
| `/projects/:id/repository/branches/:branch/protect` | PUT | Protect branch |
| `/projects/:id/repository/branches/:branch/unprotect` | PUT | Unprotect branch |

## Commits

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/projects/:id/repository/commits` | GET | List commits |
| `/projects/:id/repository/commits/:sha` | GET | Get single commit |
| `/projects/:id/repository/commits` | POST | Create commit |

## Merge Requests

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/projects/:id/merge_requests` | GET | List merge requests |
| `/projects/:id/merge_requests/:iid` | GET | Get single merge request |
| `/projects/:id/merge_requests` | POST | Create merge request |
| `/projects/:id/merge_requests/:iid` | PUT | Update merge request |

## Issues

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/projects/:id/issues` | GET | List issues |
| `/projects/:id/issues/:iid` | GET | Get single issue |
| `/projects/:id/issues` | POST | Create issue |
| `/projects/:id/issues/:iid` | PUT | Update issue |

## Groups

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/groups` | GET | List all groups |
| `/groups/:id` | GET | Get single group |
| `/groups/:id/projects` | GET | List projects in group |
| `/groups` | POST | Create group |

## Users

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/user` | GET | Get current user |
| `/users` | GET | List users |
| `/users/:id` | GET | Get single user |

## Pagination

All list endpoints support pagination:
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)

Response headers include:
- `X-Total-Pages`: Total number of pages
- `X-Total`: Total number of items
- `X-Page`: Current page
- `X-Per-Page`: Items per page

## Rate Limiting

Headers in response:
- `RateLimit-Limit`: Total requests allowed
- `RateLimit-Remaining`: Requests remaining
- `RateLimit-Reset`: Unix timestamp when limit resets

## Error Responses

```json
{
  "message": "401 Unauthorized",
  "error": "unauthorized"
}

{
  "message": "404 Not Found",
  "error": "not_found"
}

{
  "message": "500 Internal Server Error",
  "error": "internal_server_error"
}
```