require_relative '../lib/python/parser'
require_relative '../lib/python/tokenizer'
require_relative '../lib/ruby/parser'
require_relative '../lib/ruby/tokenizer'
require 'spec_helper'

RSpec.describe 'RV Compiler Parser', type: :unit do
  describe 'Python Parser' do
    it 'parses a with open as f: statement into a WithNode' do
      code = "with open('file.txt') as f:\n  print(f.read())"
      tokens = Python::Tokenizer.new(code).tokenize
      parser = Python::Parser.new(tokens)
      ast = parser.parse
      
      with_node = ast.nodes.first
      expect(with_node).to be_a(WithNode)
      expect(with_node.var_name).to eq("f")
    end

    it 'correctly handles nested class hierarchies' do
      code = "class A:\n  def __init__(self):\n    pass\nclass B(A):\n  pass"
      tokens = Python::Tokenizer.new(code).tokenize
      parser = Python::Parser.new(tokens)
      ast = parser.parse
      
      class_b = ast.nodes.last
      expect(class_b.parent_name).to eq("A")
    end
  end

  describe 'Ruby Parser' do
    it 'parses the super keyword into a SuperNode' do
      code = "super(name)"
      tokens = Ruby::Tokenizer.new(code).tokenize
      parser = Ruby::Parser.new(tokens)
      ast = parser.parse
      
      super_node = ast.nodes.first
      expect(super_node).to be_a(SuperNode)
      expect(super_node.arg_exprs.first.value).to eq("name")
    end

    it 'manages instance variable assignments correctly' do
      code = "@score = 100"
      tokens = Ruby::Tokenizer.new(code).tokenize
      parser = Ruby::Parser.new(tokens)
      ast = parser.parse
      
      assign_node = ast.nodes.first
      expect(assign_node.name.value).to eq("@score")
    end
  end
end
