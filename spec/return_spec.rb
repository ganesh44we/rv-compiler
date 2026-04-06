require_relative '../lib/tokenizer'
require_relative '../lib/parser'
require_relative '../lib/generator'

RSpec.describe 'Final Compiler' do
  describe Generator do
    it 'automatically returns the last expression in a function' do
      ast = DefNode.new("f", [], BlockNode.new([IntegerNode.new(1)]))
      js = Generator.new.generate(ast)
      expect(js).to include("return 1;")
    end

    it 'handles automatic returns in if/else branches' do
      ast = DefNode.new("f", ["n"], 
        BlockNode.new([
          IfNode.new(
            BinaryOpNode.new(:EQ, VarRefNode.new("n"), IntegerNode.new(0)),
            BlockNode.new([IntegerNode.new(1)]),
            BlockNode.new([IntegerNode.new(2)])
          )
        ])
      )
      js = Generator.new.generate(ast)
      expect(js).to include("return 1;")
      expect(js).to include("return 2;")
    end

    it 'does NOT return for while loops' do
      ast = WhileNode.new(BooleanNode.new(true), BlockNode.new([IntegerNode.new(1)]))
      js = Generator.new.generate(ast)
      expect(js).not_to include("return 1;")
    end
  end
end
