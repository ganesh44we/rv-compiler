# "Big Scale" Multi-Language Standard Library Showcase

# 1. Advanced Data Structures (Sets & Tuples)
my_set = {1, 2, 2, 3, 3, 4} # Duplicates will be removed in JS Set
print("Set elements (should be 1,2,3,4):")
print(my_set)

my_tuple = (10, "constant", True)
print("Tuple element at index 1:")
print(my_tuple[1])

# 2. Built-in Functions mapping (len, range)
my_list = [10, 20, 30]
print("Length of list [10, 20, 30]:")
print(len(my_list))

print("Range(5) converted to Array:")
print(range(5))

# 3. String & Array Method mapping (append, strip, upper, lower)
greeting = "   hello world   "
print("Cleaned and Shouting Greeting:")
print(greeting.strip().upper())

my_list.append(40)
print("List after append(40):")
print(my_list)

# 4. Dictionary support (already exists, but verifying consistency)
user = {"name": "Ganesh", "role": "Developer"}
print("User Name from Dict:")
print(user["name"])

# 5. Complex logic combining everything
def process_data(items):
    results = []
    for i in range(len(items)):
        val = items[i]
        if val > 15:
            results.append(val * 2)
    results

print("Processed data [10, 20, 30] (val > 15 -> val * 2):")
# Note: Since I don't have for-in yet, I'll use a while loop style if needed, 
# but I can use each/map if I want to show off functional style.
# For now, let's just stick to what works.

# Actually, let's use a while loop for the process_data logic to be safe
def manual_process(items):
    res = []
    i = 0
    while i < len(items):
        if items[i] > 15:
            res.append(items[i] * 2)
        i = i + 1
    res

print(manual_process([10, 20, 30]))
