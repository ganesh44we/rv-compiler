module Ruby
  class Tokenizer
    TOKEN_TYPES = [
      [:DEF, /\bdef\b/],
      [:END, /\bend\b/],
      [:CLASS, /\bclass\b/],
      [:IF, /\bif\b/],
      [:ELSE, /\belse\b/],
      [:WHILE, /\bwhile\b/],
      [:BEGIN, /\bbegin\b/],
      [:RESCUE, /\brescue\b/],
      [:ENSURE, /\bensure\b/],
      [:RAISE, /\braise\b/],
      [:SUPER, /\bsuper\b/],
      [:MATCH, /\bmatch\b/],
      [:CASE, /\bcase\b/],
      [:REQUIRE, /\brequire\b/],
      [:TYPE, /\btype\b/],
      [:ALIAS, /\balias\b/],
      [:TRUE, /\btrue\b/],
      [:FALSE, /\bfalse\b/],
      [:LAMBDA, /->/],
      [:ARROW, /=>/],
      [:STRING, /("[^"]*"|'[^']*')/],
      [:INSTANCE_VAR, /@[a-zA-Z_][a-zA-Z0-9_]*/],
      [:IDENTIFIER, /\b[a-zA-Z_][a-zA-Z0-9_]*\b/],
      [:INTEGER, /\b[0-9]+\b/],
      [:EQ, /==/],
      [:NEQ, /!=/],
      [:LEQ, /<=/],
      [:GEQ, />=/],
      [:LT, /</],
      [:GT, />/],
      [:ASSIGN, /=/],
      [:PLUS, /\+/],
      [:MINUS, /-/],
      [:STAR, /\*/],
      [:SLASH, /\//],
      [:MODULO, /%/],
      [:DOT, /\./],
      [:COLON, /:/],
      [:COMMA, /,/],
      [:OPAREN, /\(/],
      [:CPAREN, /\)/],
      [:OBRACK, /\[/],
      [:CBRACK, /\]/],
      [:OBRACE, /\{/],
      [:CBRACE, /\}/],
    ]

    def initialize(code)
      @code = code
      @line = 1
      @column = 1
    end

    def tokenize
      tokens = []
      until @code.empty?
        if @code =~ /\A\s+/
          match = $&
          update_position(match)
          @code = @code[match.length..-1]
          next
        end

        if @code =~ /\A#/
          match = @code.match(/\A#.*/).to_s
          @code = @code[match.length..-1]
          next
        end
        
        break if @code.empty?
        
        tokens << tokenize_one_token
      end
      tokens
    end

    def tokenize_one_token
      TOKEN_TYPES.each do |type, re|
        re = /\A#{re}/
        if @code =~ re
          value = $&
          token = { type: type, value: value, line: @line, column: @column }
          @code = @code[value.length..-1]
          update_position(value)
          return token
        end
      end

      raise "Unexpected character: #{@code[0].inspect} at line #{@line}, column #{@column}"
    end

    private

    def update_position(text)
      new_lines = text.count("\n")
      if new_lines > 0
        @line += new_lines
        # Use -1 limit to keep trailing empty strings from newlines
        @column = text.split("\n", -1).last.length + 1
      else
        @column += text.length
      end
    end
  end
end
