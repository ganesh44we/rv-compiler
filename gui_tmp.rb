# 💎 RV Ruby — Full-Stack Example
require "net/http"

# Networking — fetch from GitHub API
response = Net::HTTP.get("https://api.github.com")
puts "GitHub response length: " + response.length.to_s

# Git status check
status = git.status()
puts "Git Status:"
puts status

# Classic OOP
class Robot
  def initialize(name)
    @name = name
  end
  def greet
    "Hello from " + @name
  end
end

bot = Robot.new("RV-Ruby")
puts bot.greet