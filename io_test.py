# RV Compiler: Python File I/O Test

filename = "python_test.txt"
content = "Hello from RV Python!\nLearning Compilers is fun."

print("--- Writing to file: " + filename + " ---")
# Standard open/write
f = open(filename, "w")
f.write(content)
f.close()

print("--- Reading back with 'with' statement ---")
# Idiomatic with statement
with open(filename, "r") as f:
    data = f.read()
    print("Content read from file:")
    print(data)

print("--- Python I/O Test Complete ---")
