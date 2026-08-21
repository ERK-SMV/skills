#!/usr/bin/env python3

import requests
import json
import sys

# Simple FNFE API login script
# Usage: python3 login.py username password

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 login.py username password")
        sys.exit(1)
    
    username = sys.argv[1]
    password = sys.argv[2]
    
    # API endpoint
    url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/auth/login"
    
    # JSON payload
    payload = {
        "login": username,
        "password": password
    }
    
    # Make the request
    response = requests.post(url, json=payload)
    
    # Print the response
    print("Status Code:", response.status_code)
    print("Response:", json.dumps(response.json(), indent=2))
    print("Auth Token:", response.cookies.get("fastapi_auth_partner"))