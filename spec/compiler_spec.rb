require_relative '../lib/tokenizer'
require_relative '../lib/parser'
require_relative '../lib/generator'

RSpec.describe 'Enhanced Compiler' do
  describe Tokenizer do
    it 'tokenizes math operators' do
      tokens = Tokenizer.new("a + b * c / d - e").tokenize
      expect(tokens.map { |t| t[:type] }).to include(:PLUS, :STAR, :SLASH, :MINUS)
    end
  end

  describe Parser do
    it 'parses multiple function definitions' do
      source = "def a() 1 end def b() 2 end"
      tokens = Tokenizer.new(source).tokenize
      ast = Parser.new(tokens).parse
      expect(ast.nodes.length).to eq(2)
      expect(ast.nodes[0].name).to eq("a")
      expect(ast.nodes[1].name).to eq("b")
    end

    it 'parses binary expressions' do
      tokens = Tokenizer.new("def f() 1 + 2 end").tokenize
      ast = Parser.new(tokens).parse
      expect(ast.nodes.first.body.nodes.first).to be_a(BinaryOpNode)
      expect(ast.nodes.first.body.nodes.first.op).to eq(:PLUS)
    end
  end

  describe Generator do
    it 'generates JavaScript for multiple functions' do
      ast = ProgramNode.new([
        DefNode.new("a", [], BlockNode.new([IntegerNode.new(1)])),
        DefNode.new("b", [], BlockNode.new([IntegerNode.new(2)]))
      ])
      js = Generator.new.generate(ast)
      expect(js).to include("function a()")
      expect(js).to include("return 1;")
      expect(js).to include("function b()")
      expect(js).to include("return 2;")
    end

    it 'generates JavaScript for binary expressions' do
      ast = BinaryOpNode.new(:PLUS, IntegerNode.new(1), IntegerNode.new(2))
      js = Generator.new.generate(ast)
      expect(js).to eq("1 + 2")
    end
  end
end
