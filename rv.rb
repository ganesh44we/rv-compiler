#!/usr/bin/env ruby

require 'optparse'
require 'json'
require_relative 'lib/shared/nodes'
require_relative 'lib/shared/generator'
require_relative 'lib/shared/errors'

# RV Compiler v1.1 - The Multi-Language High-End Translation Engine
BANNER = <<~'EOF'
  ______     __     __
 /      \   |  \   |  \
|  $$$$$$\  | $$   | $$
| $$__| $$  | $$   | $$
| $$    $$   \$$\ /  $$
| $$$$$$$\    \$$\  $$ 
| $$  | $$     \$$ $$  
| $$  | $$      \$$$   
 \$$   \$$       \$  v1.1 (High-End CLI)
  RV MULTI-LANGUAGE COMPILER
EOF

options = {
  output: 'test.js',
  run: false,
  lang: nil,
  lex: false,
  ast: false,
  verbose: false
}

OptionParser.new do |opts|
  opts.banner = BANNER + "\nUsage: rv [options] <source_file>"

  opts.on("-o", "--output FILE", "Specify the target JavaScript filename (default: test.js)") do |v|
    options[:output] = v
  end

  opts.on("-r", "--run", "Compile and execute the code immediately with Node.js") do |v|
    options[:run] = v
  end

  opts.on("-l", "--lang LANG", "Manually specify source language (ruby or python)") do |v|
    options[:lang] = v
  end

  opts.on("--lex", "Print the token stream and exit (Introspection)") do
    options[:lex] = true
  end

  opts.on("--ast", "Print the Abstract Syntax Tree and exit (Introspection)") do
    options[:ast] = true
  end

  opts.on("--verbose", "Show internal performance timings and verbose output") do
    options[:verbose] = true
  end

  opts.on("--optimize", "Apply high-performance peephole optimizations to the output") do
    options[:optimize] = true
  end

  opts.on("-v", "--version", "Show RV Compiler version") do
    puts "RV Compiler v1.1.0 (High-End Edition)"
    exit
  end

  opts.on("-h", "--help", "Show this beautiful help guide") do
    puts opts
    exit
  end
end.parse!

filename = ARGV[0]
if filename.nil?
  puts "Error: No source file specified."
  puts "Run 'rv --help' for usage guide."
  exit 1
end

begin
  start_time = Time.now
  code = File.read(filename)
  
  # Detection logic
  lang = options[:lang] || (filename.end_with?('.py') ? 'python' : 'ruby')

  if lang == 'python'
    require_relative 'lib/python/tokenizer'
    require_relative 'lib/python/parser'
    puts "[RV] Building Python Source: #{filename}..." if options[:verbose]
    tokens = Python::Tokenizer.new(code).tokenize
    
    if options[:lex]
      puts "\n--- [RV] Token Stream (Lex) ---"
      tokens.each { |t| p t }
      exit
    end

    ast = Python::Parser.new(tokens, filename: filename, code: code).parse
  else
    require_relative 'lib/ruby/tokenizer'
    require_relative 'lib/ruby/parser'
    puts "[RV] Building Ruby Source: #{filename}..." if options[:verbose]
    tokens = Ruby::Tokenizer.new(code).tokenize
    
    if options[:lex]
      puts "\n--- [RV] Token Stream (Lex) ---"
      tokens.each { |t| p t }
      exit
    end

    ast = Ruby::Parser.new(tokens, filename: filename, code: code).parse
  end

  if options[:ast]
    puts "\n--- [RV] Abstract Syntax Tree ---"
    puts JSON.pretty_generate(ast.to_h) rescue p ast
    exit
  end

  # Generation
  js_code = Shared::Generator.new.generate(ast)

  if options[:optimize]
    require_relative 'lib/shared/optimizer'
    puts "[RV] Optimizing JavaScript Output..." if options[:verbose]
    js_code = Shared::Optimizer.new(js_code).optimize
  end

  File.write(options[:output], js_code)

  end_time = Time.now
  puts "[RV] Compilation Successful! -> #{options[:output]}"
  puts "[RV] Performance: #{(end_time - start_time).round(4)}s" if options[:verbose]

  if options[:run]
    puts "\n[RV] Executing with Node.js..."
    puts "-" * 40
    system("node #{options[:output]}")
    puts "-" * 40
  end

rescue RV::CompileError => e
  $stderr.puts "\e[31m" # Red
  $stderr.puts e.full_report
  $stderr.puts "\e[0m" # Reset
  exit 1
rescue StandardError => e
  $stderr.puts "\e[31m[RV Critical Error] #{e.message}\e[0m"
  $stderr.puts e.backtrace.first(5) if options[:verbose]
  exit 1
end
