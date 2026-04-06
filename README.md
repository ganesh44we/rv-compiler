
# RV Multi-Language Compiler

**Translate Python & Ruby into JavaScript — with a high-end CLI and a full Electron GUI.**

[![Ruby](https://img.shields.io/badge/Ruby-3.x-red?logo=ruby)](https://www.ruby-lang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-required-green?logo=node.js)](https://nodejs.org/)
[![Electron](https://img.shields.io/badge/Electron-34.x-blue?logo=electron)](https://www.electronjs.org/)


</div>



## Overview

**RV Compiler** is a source-to-source compiler that translates **Python** and **Ruby** code into **JavaScript**. It features a fully hand-written lexer, parser, and code generator — no third-party parsing libraries. On top of the CLI, it ships with **RV Studio**, a polished Electron-based GUI IDE that gives you live syntax highlighting, one-click compilation, and an integrated terminal output panel.

---

## Features

- **Multi-language frontend** — supports both Python and Ruby source files
- **Auto-detection** — automatically detects the source language from file extension
- **Full AST pipeline** — Lexer → Parser → AST → Code Generator
- **Peephole optimizer** — optional `--optimize` flag for cleaner output
- **Introspection modes** — inspect the token stream (`--lex`) or the full AST (`--ast`)
- **Run mode** — compile and immediately execute with Node.js (`--run`)
- **RV Studio GUI** — Electron app with a code editor, file browser, and live output
- **RV Runtime Library** — built-in `rv_lib.js` shims for NumPy, Pandas, Net/HTTP, Git, and more
- **RSpec test suite** — integration and unit tests covering lexer, parser, and compiler

---

## Architecture

```
Source File (.py / .rb)
        │
        ▼
   ┌─────────┐
   │  Lexer  │  →  Token Stream
   └─────────┘
        │
        ▼
   ┌─────────┐
   │ Parser  │  →  Abstract Syntax Tree (AST)
   └─────────┘
        │
        ▼
   ┌───────────┐
   │ Optimizer │  (optional --optimize)
   └───────────┘
        │
        ▼
   ┌───────────┐
   │ Generator │  →  JavaScript output
   └───────────┘
        │
        ▼
   output.js  (optionally executed by Node.js)
```

The compiler has **separate lexers and parsers** for Python and Ruby (`lib/python/`, `lib/ruby/`), sharing a common generator and node definitions (`lib/shared/`).

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Ruby | 3.0+ | Run the compiler CLI |
| Node.js | 18+ | Execute compiled output (`--run` mode) |
| npm | 9+ | Install Electron for the GUI |
| RSpec | 3.x | Run the test suite (optional) |

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/ganesh44we/rv-compiler.git
cd rv-compiler
```

### 2. Install Node dependencies (for the GUI)

```bash
npm install
```

### 3. Make the CLI executable

```bash
chmod +x bin/rv
```

### 4. (Optional) Add to your PATH

```bash
export PATH="$PATH:$(pwd)/bin"
```

Or add that line to your `~/.zshrc` / `~/.bashrc` for a permanent install.

### 5. (Optional) Install RSpec for tests

```bash
gem install rspec
```

---

## CLI Usage

```
Usage: rv [options] <source_file>

Options:
  -o, --output FILE     Output JavaScript filename (default: test.js)
  -r, --run             Compile and immediately execute with Node.js
  -l, --lang LANG       Manually specify language: ruby or python
      --lex             Print the token stream and exit
      --ast             Print the Abstract Syntax Tree and exit
      --optimize        Apply peephole optimizations to output
      --verbose         Show performance timings and verbose output
  -h, --help            Show this help message
```

### Quick Examples

**Compile a Python file to JavaScript:**
```bash
rv biggest.py -o output.js
```

**Compile and run immediately:**
```bash
rv biggest.py --run
```

**Compile a Ruby file with optimization:**
```bash
rv biggest.rb -o output.js --optimize
```

**Inspect the token stream:**
```bash
rv science.py --lex
```

**Print the AST:**
```bash
rv biggest.rb --ast
```

**Force language detection:**
```bash
rv myfile.src --lang python --run
```

---

## GUI Usage (RV Studio)

RV Studio is a full Electron desktop app with an editor and live output panel.

### Launch the GUI

```bash
npm start
```

### GUI Features

- **File open** — load any `.py`, `.rb`, or `.src` file
- **Live editor** — edit your source code with syntax-aware display
- **Compile button** — one-click compilation to JavaScript
- **Run button** — compile and execute, streaming output to the console panel
- **Output panel** — see compiler output, runtime logs, and errors in real time
- **Language selector** — override auto-detection if needed

---

## Language Support

### Python Features

| Feature | Supported |
|---------|-----------|
| Variables & arithmetic | ✅ |
| Functions (`def`) | ✅ |
| Classes & inheritance | ✅ |
| `if / elif / else` | ✅ |
| `for` / `while` loops | ✅ |
| Lists, dicts, sets | ✅ |
| `import` statements | ✅ |
| `try / except` | ✅ |
| Lambda expressions | ✅ |
| NumPy / Pandas shims | ✅ |
| `requests` HTTP shim | ✅ |

### Ruby Features

| Feature | Supported |
|---------|-----------|
| Variables & arithmetic | ✅ |
| Methods (`def`) | ✅ |
| Classes & inheritance | ✅ |
| `if / elsif / else` | ✅ |
| `while` / `each` loops | ✅ |
| Arrays & hashes | ✅ |
| `require` / `require_relative` | ✅ |
| `begin / rescue` | ✅ |
| Blocks & lambdas | ✅ |
| `net/http` shim | ✅ |

---

## Project Structure

```
rv-compiler/
├── bin/
│   └── rv                    # CLI entry point (executable)
├── lib/
│   ├── python/
│   │   ├── lexer.rb          # Python tokenizer
│   │   └── parser.rb         # Python parser → AST
│   ├── ruby/
│   │   ├── lexer.rb          # Ruby tokenizer
│   │   └── parser.rb         # Ruby parser → AST
│   └── shared/
│       ├── nodes.rb          # AST node definitions
│       ├── generator.rb      # AST → JavaScript code generator
│       ├── optimizer.rb      # Peephole optimizer
│       ├── errors.rb         # Custom error types
│       └── rv_lib.js         # Runtime shim library
├── spec/
│   ├── spec_helper.rb        # RSpec config & helpers
│   ├── lexer_spec.rb         # Lexer unit tests
│   ├── parser_spec.rb        # Parser unit tests
│   ├── compiler_spec.rb      # Compiler unit tests
│   ├── return_spec.rb        # Return statement tests
│   └── integration_spec.rb   # End-to-end integration tests
├── biggest.py                # Python showcase / test file
├── biggest.rb                # Ruby showcase / test file
├── science.py                # Data science showcase
├── net_demo.py               # HTTP networking demo
├── io_test.py                # Python I/O tests
├── io_test.rb                # Ruby I/O tests
├── bad_code.py               # Error handling test cases
├── rv.rb                     # Core compiler orchestrator
├── index.html                # RV Studio GUI frontend
├── main.js                   # Electron main process
├── renderer.js               # Electron renderer process
├── preload.js                # Electron preload script
├── style.css                 # GUI styles
├── package.json              # Node dependencies
└── .ruby-version             # Ruby version pin
```

---

## Running Tests

The test suite uses **RSpec** and covers lexer, parser, and end-to-end compilation.

```bash
# Run all tests
rspec

# Run a specific spec file
rspec spec/lexer_spec.rb
rspec spec/integration_spec.rb

# Run with detailed output
rspec --format documentation
```

### What's tested

- **Lexer specs** — token types, string literals, operators, edge cases
- **Parser specs** — expression parsing, statement parsing, class/function definitions
- **Compiler specs** — full compile pipeline, output correctness
- **Return specs** — return statement handling across contexts
- **Integration specs** — compile and run `biggest.py`, `biggest.rb`, `science.py` end-to-end

---

## Examples

### Python → JavaScript

**Input (`biggest.py` excerpt):**
```python
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

print(factorial(5))
```

**Output (`test.js` excerpt):**
```javascript
function factorial(n) {
  if (n <= 1) {
    return 1;
  }
  return n * factorial(n - 1);
}
console.log(factorial(5));
```

### Ruby → JavaScript

**Input (`biggest.rb` excerpt):**
```ruby
def factorial(n)
  return 1 if n <= 1
  n * factorial(n - 1)
end

puts factorial(5)
```

**Output:**
```javascript
function factorial(n) {
  if (n <= 1) { return 1; }
  return n * factorial(n - 1);
}
console.log(factorial(5));
```

---

## .gitignore Recommendations

Make sure your repo excludes generated and system files:

```gitignore
node_modules/
.DS_Store
*.js.map
test.js
.ruby-lsp/
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please make sure all RSpec tests pass before submitting.

---

<div align="center">

Built with ❤️ by **ganesh44we** · [github.com/ganesh44we/rv-compiler](https://github.com/ganesh44we/rv-compiler)

</div>
