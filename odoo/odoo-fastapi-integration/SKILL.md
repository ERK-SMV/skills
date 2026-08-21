---
name: odoo-fastapi-integration
title: Odoo FastAPI Integration
description: Use for Odoo FastAPI authentication and API operations.
trigger: >-
  - User needs to connect to Odoo FastAPI endpoints
  - Working with FNFE API or similar Odoo-FastAPI integrations
  - Authentication and API request patterns for Odoo REST APIs
category: odoo
---

# Odoo FastAPI Integration

## Authentication

### Basic Login Pattern

```python
import requests
import json

# Simple login to FNFE API
url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/auth/login"
payload = {
    "login": "username",
    "password": "password"
}

response = requests.post(url, json=payload)
print("Status:", response.status_code)
print("Response:", response.text)
print("Auth Token:", response.cookies.get("fastapi_auth_partner"))
```

### Secure Login with Password Prompt

```python
import requests
import getpass

username = input("Username: ")
password = getpass.getpass("Password: ")

url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/auth/login"
payload = {"login": username, "password": password}

response = requests.post(url, json=payload)
auth_token = response.cookies.get("fastapi_auth_partner")
```

## API Request Patterns

### Session Management

```python
# Create session for authenticated requests
session = requests.Session()

# Login
login_url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/auth/login"
login_payload = {"login": "username", "password": "password"}
login_response = session.post(login_url, json=login_payload)

# Use session for authenticated requests
customer_response = session.get("https://fnfempe--preprod-18-0.ci-akretion.com/api/customer")
```

### Error Handling

```python
try:
    response = requests.post(url, json=payload)
    response.raise_for_status()
    data = response.json()
except requests.exceptions.HTTPError as http_err:
    print(f"HTTP error: {http_err}")
    if response.status_code == 422:
        print("Validation error - check credentials")
except Exception as err:
    print(f"Error: {err}")
```

## Common Endpoints

### Customer Data

```python
# Get customer data
customer_url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/customer"
customer_response = session.get(customer_url)
customer_data = customer_response.json()

# Update customer data
update_payload = {"name": "New Name", "email": "new@email.com"}
update_response = session.post(customer_url, json=update_payload)
```

### Analysis Operations

```python
# Search analyses
analyses_url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/analyses"
params = {"page": 1, "page_size": 20}
analyses_response = session.get(analyses_url, params=params)

# Create analysis
create_payload = {"title": "New Analysis"}
create_response = session.post(analyses_url, json=create_payload)
```

## Pitfalls

1. **Authentication Token**: The auth token is stored in cookies, not in response JSON
2. **Session Management**: Always use `requests.Session()` to maintain cookies between requests
3. **Error Codes**: 422 indicates validation errors, often due to incorrect credentials
4. **Password Security**: Avoid passing passwords as command-line arguments when possible

## User Preferences

- User prefers simple, direct Python scripts without complex structures
- User wants minimal formatting and straightforward output
- User prefers command-line argument approach for automation
- User prefers secure password entry when interactive

## References

- Simple login script: `references/simple_login.py`
- Minimal login script: `references/minimal_login.py`
- Secure login with password prompt: `references/secure_login.py`