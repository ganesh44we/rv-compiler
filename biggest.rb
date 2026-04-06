# [RV Compiler] The ultimate Ruby "Biggest" Showcase Script (biggest.rb)

require "numpy"
require "pandas"

# 1. OOP (Inheritance and Instance State)
class Entity
  def initialize(name)
    @name = name
  end
end

class SmartRobot < Entity
  def initialize(name, version)
    super(name)
    @version = version
  end

  def identity
    print("I am " + @name + " v" + @version)
  end
end

# 2. Logic (Recursion: Factorial)
def factorial(n)
  if n <= 1
    1
  else
    n * factorial(n - 1)
  end
end

# 3. Data Science & Standard Library (require parity)
def test_data
  # NumPy through require "numpy"
  scores = np.array([85, 92, 78, 90, 88])
  print("Ruby NumPy Mean:")
  print(scores.mean())

  # Pandas through require "pandas"
  df = pd.DataFrame([{"name": "Alice", "math": 95}, {"name": "Bob", "math": 72}])
  print("Ruby Pandas Description:")
  print(df.describe())
end

# 4. Error Handling (begin/rescue/ensure)
def safe_execute(val)
  begin
    print("Ruby checking value: " + val)
    if val == "crash"
      raise("Ruby System Failure")
    end
    print("Ruby System OK")
  rescue
    print("Ruby caught crash! Recovery active.")
  ensure
    print("Ruby cleanup complete.")
  end
end

# 5. Performance Stress Test (10,000 items)
def stress_test
  print("--- Starting 10,000 item stress test in Ruby ---")
  data = []
  i = 0
  while i < 10000
    # Modulo operator check
    score = (i * 17) % 100
    data.push({"id": i, "score": score})
    i = i + 1
  end
  
  df = pd.DataFrame(data)
  print("Stats for 10,000 Ruby-generated rows:")
  print(df.describe())
end

# --- MAIN EXECUTION ---
print("--- [RV] STARTING RUBY MEGA SHOWCASE ---")

robot = SmartRobot.new("RubyBot", "3.0")
robot.identity()

print("Ruby Factorial(5):")
print(factorial(5))

test_data()

print("--- Testing Ruby Error Handling ---")
safe_execute("startup")
safe_execute("crash")

stress_test()

print("--- [RV] RUBY MEGA SHOWCASE COMPLETE ---")
