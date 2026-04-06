<div align="center">

```
  ______     __     __
 /      \   |  \   |  \
|  $$$$$$\  | $$   | $$
| $$__| $$  | $$   | $$
| $$    $$   \$$\ /  $$
| $$$$$$$\    \$$\  $$
| $$  | $$     \$$ $$
| $$  | $$      \$$$
 \$$   \$$       \$  v1.1
  RV MULTI-LANGUAGE COMPILER
```

# RV Compiler

**A source-to-source compiler that translates Ruby and Python into JavaScript.**  
Ships with a full-featured CLI and a dark-themed Electron desktop IDE — *RV Studio*.

![Ruby](https://img.shields.io/badge/Ruby-3.3.0-CC342D?logo=ruby&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-%E2%89%A518-339933?logo=node.js&logoColor=white)
![Electron](https://img.shields.io/badge/Electron-34.x-47848F?logo=electron&logoColor=white)
![License](https://img.shields.io/badge/license-proprietary-lightgrey)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [CLI Usage](#cli-usage)
- [GUI — RV Studio](#gui--rv-studio)
- [Language Support](#language-support)
- [How It Works](#how-it-works)
- [Running Tests](#running-tests)
- [Development Notes](#development-notes)

---

## Overview

RV compiles **Ruby** and **Python** source code into clean **JavaScript**, following a classical compiler pipeline:

```
Source (.rb / .py)  →  Tokenizer  →  Parser  →  AST  →  Generator  →  output.js
                                                               ↓ (optional)
                                                           Optimizer
```

It ships with two interfaces:

| Interface | How to start | Description |
|-----------|-------------|-------------|
| **CLI** (`rv`) | `./bin/rv file.rb` | Full-featured command-line compiler |
| **RV Studio** | `npm start` | Electron desktop IDE with live compilation |

---

## Features

| | Feature |
|--|---------|
| 🔀 | **Dual language** — Ruby (`.rb`) and Python (`.py`), auto-detected by file extension |
| 🔍 | **Introspection** — print the token stream (`--lex`) or AST (`--ast`) at any stage |
| ⚡ | **Peephole optimizer** — constant folding, `i++` rewriting, dead-code removal (`--optimize`) |
| ▶️ | **Compile + run** — execute output immediately with Node.js (`--run`) |
| 🎨 | **Rich error reporting** — colorized output with line, column, and a `^` caret diagnostic |
| 📦 | **Bundled runtime** — `rv_lib.js` standard library injected into every compiled file |
| 🖥️ | **RV Studio** — dark-themed Electron IDE with code editor, output panel, and run button |
| 🧪 | **Full test suite** — RSpec specs for lexer, parser, generator, and end-to-end runs |

---

## Project Structure

```
comp/
├── bin/
│   └── rv                       # Shell wrapper — CLI entry point
│
├── lib/
│   ├── python/
│   │   ├── tokenizer.rb         # Python lexer
│   │   └── parser.rb            # Python → AST
│   ├── ruby/
│   │   ├── tokenizer.rb         # Ruby lexer
│   │   └── parser.rb            # Ruby → AST
│   └── shared/
│       ├── nodes.rb             # All AST node Structs (DefNode, IfNode, CallNode …)
│       ├── generator.rb         # AST walker — emits JavaScript
│       ├── optimizer.rb         # Peephole optimization passes
│       ├── errors.rb            # RV::CompileError with visual diagnostics
│       └── rv_lib.js            # RV runtime — prepended to every compiled output
│
├── spec/
│   ├── spec_helper.rb           # RSpec config + shared helpers
│   ├── lexer_spec.rb            # Tokenizer unit tests
│   ├── parser_spec.rb           # AST construction tests
│   ├── return_spec.rb           # Return statement edge cases
│   ├── compiler_spec.rb         # Full pipeline tests
│   └── integration_spec.rb      # End-to-end compile + execute tests
│
├── rv.rb                        # CLI core logic
├── main.js                      # Electron main process
├── preload.js                   # contextBridge API (main ↔ renderer)
├── renderer.js                  # GUI logic
├── index.html                   # RV Studio markup
├── style.css                    # RV Studio styles
├── test.src                     # Sample: Ruby error-handling showcase
├── error.src                    # Sample: intentional syntax error
├── package.json                 # npm manifest (Electron ~34, start script)
└── .ruby-version                # Pins Ruby 3.3.0
```

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| **Ruby** | `3.3.0` | Pinned via `.ruby-version` — rbenv/rvm will auto-switch |
| **Node.js** | ≥ 18 | Required for `--run` and RV Studio |
| **npm** | ≥ 9 | Required for RV Studio only |
| **RSpec** | latest | Required for the test suite only |

---

## Installation

```bash
# 1. Clone the repo
git clone <your-repo-url> rv-compiler
cd rv-compiler

# 2. Make the CLI executable
chmod +x bin/rv

# 3. Install Ruby test dependencies (optional)
gem install rspec

# 4. Install GUI dependencies (optional — RV Studio only)
npm install
```

---

## CLI Usage

```bash
./bin/rv [options] <source_file>

# Or invoke the compiler directly with Ruby:
ruby rv.rb [options] <source_file>
```

### Options

| Flag | Description |
|------|-------------|
| `-o, --output FILE` | Output filename (default: `test.js`) |
| `-r, --run` | Compile then execute immediately with Node.js |
| `-l, --lang LANG` | Force language: `ruby` or `python` |
| `--lex` | Print token stream and exit |
| `--ast` | Print AST as JSON and exit |
| `--optimize` | Apply peephole optimizations to the output |
| `--verbose` | Show performance timings and diagnostic info |
| `-v, --version` | Print version and exit |
| `-h, --help` | Show help |

### Examples

```bash
# Basic compile — outputs test.js
./bin/rv my_script.rb

# Compile and run immediately
./bin/rv test.src --lang ruby --run

# Custom output filename with optimizer
./bin/rv my_script.rb -o dist/out.js --optimize

# Inspect the token stream
./bin/rv script.py --lex

# Print the full AST as JSON
./bin/rv script.rb --ast

# Compile Python, name the output, and run — all in one
./bin/rv analysis.py -o analysis.js --run

# Full diagnostic run with timing
./bin/rv my_script.rb --optimize --verbose -o out.js
```

### Successful output

```
[RV] Compilation Successful! -> out.js
[RV] Performance: 0.0031s
```

### Error output

```
[RV Compile Error] Unexpected token: EOF — expected 'end'
  at error.src:4:1

   4 | # No end here
     | ^
```

Errors exit with code `1` and print to `stderr` in red. Runtime errors from `--run` pass through directly from Node.js.

---

## GUI — RV Studio

```bash
npm start
```

RV Studio is a dark-themed desktop IDE built on Electron with a code editor, language selector, and an output panel wired to the `rv` compiler running in the background.

**Process architecture:**

```
renderer.js  ──(ipcRenderer)──▶  preload.js  ──(contextBridge)──▶  main.js
                                                                        │
                                                                   child_process
                                                                        │
                                                                     bin/rv
```

- **`main.js`** — handles `compile` and `run` IPC events, spawning `rv` as a subprocess
- **`preload.js`** — exposes `window.rvAPI` to the renderer via `contextBridge` (no `nodeIntegration`)
- **`renderer.js`** — drives all UI interactions and calls `window.rvAPI`

---

## Language Support

### Ruby

| Feature | Syntax |
|---------|--------|
| Variables | `x = 42` |
| Control flow | `if / elsif / else / end`, `while`, `for` |
| Methods | `def greet(name) ... end` |
| Classes & inheritance | `class Dog < Animal ... end` |
| Error handling | `begin / rescue / ensure / raise` |
| Collections | `[1, 2, 3]`, `{ a: 1 }` |
| String interpolation | `"Hello #{name}"` |
| Instance variables | `@name` |
| Super | `super(args)` |
| Lambdas | `->(x) { x * 2 }` |
| Pattern matching | `case val; in Integer; ...` |
| Enumerable blocks | `arr.each { \|x\| ... }` |

### Python

| Feature | Syntax |
|---------|--------|
| Variables | `x = 42` |
| Control flow | `if / elif / else`, `while`, `for` |
| Functions | `def greet(name):` |
| Classes | `class Dog(Animal):` |
| Imports | `import numpy as np` |
| Collections | `[1,2]`, `{"a": 1}`, `{1,2}`, `(1,2)` |
| Context managers | `with open(f) as fh:` |
| Lambdas | `lambda x: x * 2` |
| Error handling | `try / except / raise` |

### Module Mapping

Common library names are automatically mapped to RV runtime shims:

| Import | Compiled as |
|--------|-------------|
| `numpy` | `RV.numpy` |
| `pandas` | `RV.pandas` |
| `requests` | `requests` (global in `rv_lib.js`) |
| `git` | `RV.Git` |
| `net/http` | `RV.Net` |

---

## How It Works

The compiler is split into clearly separated, independently testable stages.

**1. Tokenizer** (`lib/ruby/tokenizer.rb` or `lib/python/tokenizer.rb`)
Scans source characters and produces a flat array of typed tokens.

**2. Parser** (`lib/ruby/parser.rb` or `lib/python/parser.rb`)
Consumes the token stream and builds an **Abstract Syntax Tree** from plain Ruby `Struct` types — `DefNode`, `IfNode`, `ClassNode`, `CallNode`, etc. — defined in `lib/shared/nodes.rb`. Both language parsers emit the same node types, which is what lets the generator be shared.

**3. Generator** (`lib/shared/generator.rb`)
Walks the AST recursively and emits JavaScript. Prepends `rv_lib.js` (disk-cached after the first read via `@@lib_cache`) to every output file.

**4. Optimizer** (`lib/shared/optimizer.rb`, optional via `--optimize`)
Runs regex-based peephole passes over the emitted JavaScript:
- `i = i + 1` → `i++` / `i = i - 1` → `i--`
- Constant folding: `2 + 3` → `5`
- Boolean cleanup: `!!true` → `true`
- Dead-code removal: bare string statements on their own line

---

## Running Tests

```bash
# Run the full suite
bundle exec rspec

# Without Bundler
rspec

# Run individual spec files
rspec spec/lexer_spec.rb
rspec spec/parser_spec.rb
rspec spec/integration_spec.rb
```

| Spec file | What it covers |
|-----------|---------------|
| `lexer_spec.rb` | Token types, keywords, string and number literals |
| `parser_spec.rb` | AST node shapes, operator precedence, nested structures |
| `return_spec.rb` | Early returns, nested returns, return value propagation |
| `compiler_spec.rb` | Full pipeline correctness, JS output structure |
| `integration_spec.rb` | Compile → execute with Node.js → assert stdout |

---

## Development Notes

- Ruby is pinned to **3.3.0** via `.ruby-version`. rbenv and rvm pick this up automatically.
- Language concerns are fully isolated — Ruby and Python each have their own tokenizer and parser. Only the generator and AST node definitions are shared.
- `rv_lib.js` is read from disk once and cached in a class variable (`@@lib_cache`) for the lifetime of the process, keeping compilation fast.
- The Electron GUI runs with `contextIsolation: true` and `nodeIntegration: false`. All system access is funnelled through `preload.js`.
- `node_modules/` bundles the full Electron (~34.x) binary tree. Do not hand-edit it — run `npm install` to regenerate if needed.
