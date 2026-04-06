module Python
  class Tokenizer
    TOKEN_TYPES = [
      [:DEF, /\bdef\b/],
      [:IF, /\bif\b/],
      [:ELIF, /\belif\b/],
      [:ELSE, /\belse\b/],
      [:WHILE, /\bwhile\b/],
      [:FOR, /\bfor\b/],
      [:IN, /\bin\b/],
      [:WITH, /\bwith\b/],
      [:AS, /\bas\b/],
      [:IMPORT, /\bimport\b/],
      [:AS, /\bas\b/],
      [:TRY, /\btry\b/],
      [:EXCEPT, /\bexcept\b/],
      [:FINALLY, /\bfinally\b/],
      [:RAISE, /\braise\b/],
      [:MATCH, /\bmatch\b/],
      [:CASE, /\bcase\b/],
      [:CLASS, /\bclass\b/],
      [:TRUE, /\bTrue\b/],
      [:FALSE, /\bFalse\b/],
      [:NONE, /\bNone\b/],
      [:STRING, /("[^"]*"|'[^']*')/],
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
      @indent_stack = [0]
      @tokens = []
    end

    def tokenize
      lines = @code.lines
      nesting_level = 0
      
      lines.each do |line_content|
        # Ignore empty lines or comment-only lines for indentation purposes
        if line_content.strip.empty? || line_content.strip.start_with?("#")
          @line += 1
          next
        end

        # Calculate indentation only if not inside brackets/parens
        if nesting_level == 0
          indent = line_content[/\A\s*/].length
          
          if indent > @indent_stack.last
            @indent_stack.push(indent)
            @tokens << { type: :INDENT, value: "", line: @line, column: 1 }
          elsif indent < @indent_stack.last
              while indent < @indent_stack.last
                @indent_stack.pop
                @tokens << { type: :DEDENT, value: "", line: @line, column: 1 }
              end
              if indent != @indent_stack.last
                raise "Indentation error at line #{@line}"
              end
          end
        end

        # Tokenize the physical line and update nesting_level
        process_line(line_content.strip)
        
        # Recalculate nesting level based on tokens in the physical line
        line_tokens = @tokens.select { |t| t[:line] == @line }
        line_tokens.each do |t|
          case t[:type]
          when :OPAREN, :OBRACK, :OBRACE then nesting_level += 1
          when :CPAREN, :CBRACK, :CBRACE then nesting_level -= 1
          end
        end

        @line += 1
      end

      # Dedent everything at EOF
      while @indent_stack.length > 1
        @indent_stack.pop
        @tokens << { type: :DEDENT, value: "", line: @line, column: 1 }
      end

      @tokens
    end

    private

    def process_line(line_code)
      @column = @indent_stack.last + 1
      until line_code.empty?
        if line_code =~ /\A\s+/
          match = $&
          @column += match.length
          line_code = line_code[match.length..-1]
          next
        end

        if line_code.start_with?("#")
          break # Ignore rest of the line
        end
        
        found = false
        TOKEN_TYPES.each do |type, re|
          re = /\A#{re}/
          if line_code =~ re
            value = $&
            @tokens << { type: type, value: value, line: @line, column: @column }
            @column += value.length
            line_code = line_code[value.length..-1]
            found = true
            break
          end
        end

        unless found
          raise "Unexpected character: #{line_code[0].inspect} at line #{@line}, column #{@column}"
        end
      end
    end
  end
end
