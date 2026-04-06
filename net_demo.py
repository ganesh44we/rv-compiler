# RV Networking & Git Demo (Python)
import requests

# Fetch from a public API
response = requests.get("https://httpbin.org/get")
print("HTTP Response received!")
print(response.text)

# Git integration
import git
branch = git.branch()
print("Current Git Branch:")
print(branch)

log = git.log(3)
print("Recent commits:")
print(log)
