#!/usr/bin/env python3

import requests
import json
import sys

# Simple FNFE API login
if len(sys.argv) != 3:
    print("Usage: python3 login.py username password")
    sys.exit(1)

username = sys.argv[1]
password = sys.argv[2]
url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/auth/login"

payload = {"login": username, "password": password}
response = requests.post(url, json=payload)

print("Status:", response.status_code)
print("Response:", response.text)
print("Auth Token:", response.cookies.get("fastapi_auth_partner"))