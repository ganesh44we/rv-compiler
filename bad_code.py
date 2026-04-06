# RV Compiler: Intentional Error Test
def test_error():
    print("This line is OK")
    # Missing colon here!
    if True
        print("This will crash the compiler")

test_error()
