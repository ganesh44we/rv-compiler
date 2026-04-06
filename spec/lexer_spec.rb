require_relative '../lib/python/tokenizer'
require_relative '../lib/ruby/tokenizer'
require 'spec_helper'

RSpec.describe 'RV Compiler Lexer', type: :unit do
  describe 'Python Tokenizer' do
    it 'correctly tokenizes indentation-based blocks' do
      code = "def foo():\n  print(1)\nprint(2)"
      tokenizer = Python::Tokenizer.new(code)
      tokens = tokenizer.tokenize
      types = tokens.map { |t| t[:type] }
      
      # In RV, print is an IDENTIFIER, not a keyword
      expect(types).to include(:DEF, :INDENT, :IDENTIFIER, :DEDENT)
    end

    it 'recognizes high-end keywords like with and as' do
      code = "with open('f') as f:"
      tokenizer = Python::Tokenizer.new(code)
      tokens = tokenizer.tokenize
      types = tokens.map { |t| t[:type] }
      
      # In RV, with and as are keywords, but open is an IDENTIFIER
      expect(types).to include(:WITH, :IDENTIFIER, :AS)
    end
  end

  describe 'Ruby Tokenizer' do
    it 'manages instance variables with the @ symbol' do
      code = "@name = 'RV'"
      tokenizer = Ruby::Tokenizer.new(code)
      tokens = tokenizer.tokenize
      types = tokens.map { |t| t[:type] }
      values = tokens.map { |t| t[:value] }
      
      expect(types).to include(:INSTANCE_VAR, :ASSIGN, :STRING)
      expect(values).to include("@name")
    end

    it 'recognizes the super keyword for inheritance' do
      code = "super(name)"
      tokenizer = Ruby::Tokenizer.new(code)
      tokens = tokenizer.tokenize
      types = tokens.map { |t| t[:type] }
      
      expect(types).to include(:SUPER)
    end
  end
end
