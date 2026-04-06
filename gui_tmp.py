# 🐍 RV Python — Full-Stack Example
import requests
import numpy as np

# Networking — fetch from GitHub API
response = requests.get("https://api.github.com")
print("GitHub API status:", response.status_code)

# Data Science — NumPy array analysis
scores = np.array([85, 92, 78, 90, 88])
print("Mean score:", scores.mean())

# Classic OOP
class Robot:
    def __init__(self, name):
        self.name = name
    def greet(self):
        return "Hello from " + self.name

bot = Robot("RV-Python")
print(bot.greet())