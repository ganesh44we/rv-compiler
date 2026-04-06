# [RV Compiler] The ultimate "Biggest" Showcase Script

# 1. OOP (Inheritance and Instance State)
class Entity:
    def __init__(self, name):
        self.name = name

class SmartRobot(Entity):
    def __init__(self, name, version):
        super().__init__(name)
        self.version = version

    def identity(self):
        print("I am " + self.name + " v" + self.version)

# 2. Logic (Recursion: Factorial)
def factorial(n):
    if n <= 1:
        1
    else:
        n * factorial(n - 1)

# 3. Data Structures & Standard Library
def test_data():
    # Set deduplication
    tags = {"ai", "robot", "ai", "rv"}
    print("Tags (Deduplicated Set):")
    print(tags)

    # Tuple for constants
    config = (1024, 768)
    print("Resolution Tuple:")
    print(config)

    # Dictionary mapping
    meta = {"lang": "python", "target": "javascript"}
    print("Language from Dict:")
    print(meta["lang"])

# 4. Error Handling & Control Flow
def safe_execute(val):
    try:
        print("Checking value: " + val)
        if val == "crash":
            raise("Intentional System Failure")
        print("System OK")
    except:
        print("Caught crash! Triggering safety protocol.")
    finally:
        print("Cleanup routine finished.")

# 5. Iteration & Chained Methods
def process_names(names):
    processed = []
    print("Processing " + len(names) + " names...")
    for i in range(len(names)):
        name = names[i]
        # Chained: strip trailing/leading and make uppercase
        clean_name = name.strip().upper()
        processed.append(clean_name)
    processed

# --- MAIN EXECUTION ---
print("--- [RV] STARTING MEGA SHOWCASE ---")

robot = SmartRobot("Nexus", "2.0")
robot.identity()

print("Factorial of 5 (Recursion):")
print(factorial(5))

test_data()

print("--- Testing Error Handling (begin/rescue) ---")
safe_execute("startup")
safe_execute("crash")

print("--- Testing Iteration & Library ---")
raw_names = ["  alice ", " bob  ", "charlie"]
results = process_names(raw_names)
print("Final results:")
print(results)

print("--- [RV] MEGA SHOWCASE COMPLETE ---")
