# RV Compiler: Ruby File I/O Test

filename = "ruby_test.txt"
content = "Hello from RV Ruby!\nProfessional File System support."

print("--- Writing to file using File.write: " + filename + " ---")
File.write(filename, content)

print("--- Reading back using File.read ---")
data = File.read(filename)
print("Ruby Content read from file:")
print(data)

print("--- Ruby I/O Test Complete ---")
