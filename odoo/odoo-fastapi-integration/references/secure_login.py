#!/usr/bin/env python3

import requests
import getpass

username = input("Username: ")
password = getpass.getpass("Password: ")

url = "https://fnfempe--preprod-18-0.ci-akretion.com/api/auth/login"
payload = {"login": username, "password": password}

response = requests.post(url, json=payload)
auth_token = response.cookies.get("fastapi_auth_partner")

print("Login successful!")
print("Auth Token:", auth_token)