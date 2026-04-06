require_relative '../shared/nodes'
require_relative '../shared/errors'

module Python
  class Parser
    def initialize(tokens, filename: nil, code: nil)
      @tokens = tokens
      @filename = filename
      @code = code
    end

    def parse
      nodes = []
      while @tokens.any?
        nodes << parse_top_level
      end
      ProgramNode.new(nodes)
    end

    def parse_top_level
      if peek(:DEF)
        parse_def
      elsif peek(:CLASS)
        parse_class
      elsif peek(:IMPORT)
        parse_import
      else
        parse_expr
      end
    end

    def parse_import
      consume(:IMPORT)
      module_name = consume(:IDENTIFIER).fetch(:value)
      alias_name = nil
      if peek(:AS)
        consume(:AS)
        alias_name = consume(:IDENTIFIER).fetch(:value)
      end
      ImportNode.new(module_name, alias_name)
    end

    def parse_class
      consume(:CLASS)
      name = consume(:IDENTIFIER).fetch(:value)
      parent_name = nil
      if peek(:OPAREN)
        consume(:OPAREN)
        parent_name = consume(:IDENTIFIER).fetch(:value)
        consume(:CPAREN)
      end
      consume(:COLON)
      methods = []
      if peek(:INDENT)
        consume(:INDENT)
        while @tokens.any? && !peek(:DEDENT)
          if peek(:DEF)
            methods << parse_def
          else
            @tokens.shift
          end
        end
        consume(:DEDENT)
      end
      ClassNode.new(name, methods, parent_name)
    end

    def parse_def
      consume(:DEF)
      name = consume(:IDENTIFIER).fetch(:value)
      arg_names = parse_arg_names
      consume(:COLON)
      body = parse_block
      DefNode.new(name, arg_names, body)
    end

    def parse_arg_names
      arg_names = []
      consume(:OPAREN)
      if peek(:IDENTIFIER)
        arg_names << consume(:IDENTIFIER).fetch(:value)
        while peek(:COMMA)
          consume(:COMMA)
          arg_names << consume(:IDENTIFIER).fetch(:value)
        end
      end
      consume(:CPAREN)
      arg_names
    end

    def parse_block
      nodes = []
      if peek(:INDENT)
        consume(:INDENT)
        while @tokens.any? && !peek(:DEDENT)
          nodes << parse_expr
        end
        consume(:DEDENT)
      else
        nodes << parse_expr
      end
      BlockNode.new(nodes)
    end

    def parse_expr
      if peek(:IF)
        parse_if
      elsif peek(:WHILE)
        parse_while
      elsif peek(:FOR)
        parse_for
      elsif peek(:WITH)
        parse_with
      elsif peek(:TRY)
        parse_try
      elsif peek(:RAISE)
        parse_raise
      else
        left = parse_binary_expr
        if peek(:ASSIGN)
          consume(:ASSIGN)
          right = parse_expr
          AssignNode.new(left, right)
        else
          left
        end
      end
    end

    def parse_with
      consume(:WITH)
      expr = parse_expr
      var_name = nil
      if peek(:AS)
        consume(:AS)
        var_name = consume(:IDENTIFIER).fetch(:value)
      end
      consume(:COLON)
      body = parse_block
      WithNode.new(expr, var_name, body)
    end

    def parse_for
      consume(:FOR)
      var_name = consume(:IDENTIFIER).fetch(:value)
      consume(:IN)
      iterable = parse_expr
      consume(:COLON)
      body = parse_block
      ForNode.new(var_name, iterable, body)
    end

    def parse_try
      consume(:TRY)
      consume(:COLON)
      body = parse_block
      rescue_body = nil
      ensure_body = nil
      
      if peek(:EXCEPT)
        consume(:EXCEPT)
        consume(:COLON)
        rescue_body = parse_block
      end
      
      if peek(:FINALLY)
        consume(:FINALLY)
        consume(:COLON)
        ensure_body = parse_block
      end
      
      RescueNode.new(body, rescue_body, ensure_body)
    end

    def parse_raise
      consume(:RAISE)
      value = parse_expr
      RaiseNode.new(value)
    end

    def parse_if
      consume(:IF)
      condition = parse_expr
      consume(:COLON)
      then_body = parse_block
      else_body = nil
      
      if peek(:ELIF)
        else_body = parse_elif
      elsif peek(:ELSE)
        consume(:ELSE)
        consume(:COLON)
        else_body = parse_block
      end
      
      IfNode.new(condition, then_body, else_body)
    end

    def parse_elif
      consume(:ELIF)
      condition = parse_expr
      consume(:COLON)
      then_body = parse_block
      else_body = nil
      
      if peek(:ELIF)
        else_body = parse_elif
      elsif peek(:ELSE)
        consume(:ELSE)
        consume(:COLON)
        else_body = parse_block
      end
      
      BlockNode.new([IfNode.new(condition, then_body, else_body)])
    end

    def parse_while
      consume(:WHILE)
      condition = parse_expr
      consume(:COLON)
      body = parse_block
      WhileNode.new(condition, body)
    end

    def parse_binary_expr
      node = parse_access
      while [:PLUS, :MINUS, :STAR, :SLASH, :MODULO, :EQ, :NEQ, :LT, :GT, :LEQ, :GEQ].include?(peek_type)
        op = @tokens.shift[:type]
        right = parse_access
        node = BinaryOpNode.new(op, node, right)
      end
      node
    end

    def parse_access
      node = parse_primary
      while peek(:DOT) || peek(:OBRACK)
        if peek(:DOT)
          consume(:DOT)
          member = consume(:IDENTIFIER).fetch(:value)
          if peek(:OPAREN)
            arg_exprs = parse_args
            node = MethodCallNode.new(node, member, arg_exprs)
          else
            node = AccessNode.new(node, member)
          end
        elsif peek(:OBRACK)
          consume(:OBRACK)
          index = parse_expr
          consume(:CBRACK)
          node = IndexNode.new(node, index)
        end
      end
      node
    end

    def parse_primary
      if peek(:INTEGER)
        parse_integer
      elsif peek(:STRING)
        parse_string
      elsif peek(:TRUE) || peek(:FALSE)
        parse_boolean
      elsif peek(:NONE)
        parse_none
      elsif peek(:OBRACK)
        parse_array
      elsif peek(:OBRACE)
        parse_set_or_dict
      elsif peek(:IDENTIFIER) && peek(:OPAREN, 1)
        parse_call
      elsif peek(:IDENTIFIER)
        parse_var_ref
      elsif peek(:OPAREN)
        parse_tuple_or_paren
      else
        tok = @tokens.first
        raise RV::CompileError.new(
          "Unexpected token #{tok ? tok[:type].inspect : 'EOF'} in parse_primary",
          filename: @filename,
          line: tok ? tok[:line] : nil,
          column: tok ? tok[:column] : nil,
          code: @code
        )
      end
    end

    def parse_tuple_or_paren
      consume(:OPAREN)
      if peek(:CPAREN)
        consume(:CPAREN)
        return TupleNode.new([])
      end
      
      first = parse_expr
      if peek(:COMMA)
        elements = [first]
        while peek(:COMMA)
          consume(:COMMA)
          break if peek(:CPAREN)
          elements << parse_expr
        end
        consume(:CPAREN)
        TupleNode.new(elements)
      else
        consume(:CPAREN)
        first
      end
    end

    def parse_set_or_dict
      consume(:OBRACE)
      if peek(:CBRACE)
        consume(:CBRACE)
        return HashNode.new([]) # {} is an empty dict in Python
      end
      
      # Look ahead to see if it's a dict or a set
      first_key_or_val = parse_expr
      if peek(:COLON)
        # It's a Dictionary
        consume(:COLON)
        val = parse_expr
        pairs = [[first_key_or_val.is_a?(StringNode) ? first_key_or_val.value.gsub('"', '') : first_key_or_val.value, val]]
        while peek(:COMMA)
          consume(:COMMA)
          break if peek(:CBRACE)
          k = parse_expr
          consume(:COLON)
          v = parse_expr
          pairs << [k.is_a?(StringNode) ? k.value.gsub('"', '') : (k.respond_to?(:value) ? k.value : k.inspect), v]
        end
        consume(:CBRACE)
        HashNode.new(pairs)
      else
        # It's a Set
        elements = [first_key_or_val]
        while peek(:COMMA)
          consume(:COMMA)
          break if peek(:CBRACE)
          elements << parse_expr
        end
        consume(:CBRACE)
        SetNode.new(elements)
      end
    end

    def parse_args
      arg_exprs = []
      consume(:OPAREN)
      if !peek(:CPAREN)
        arg_exprs << parse_expr
        while peek(:COMMA)
          consume(:COMMA)
          arg_exprs << parse_expr
        end
      end
      consume(:CPAREN)
      arg_exprs
    end

    def parse_array
      consume(:OBRACK)
      elements = []
      if !peek(:CBRACK)
        elements << parse_expr
        while peek(:COMMA)
          consume(:COMMA)
          elements << parse_expr
        end
      end
      consume(:CBRACK)
      ArrayNode.new(elements)
    end

    def parse_string
      StringNode.new(consume(:STRING).fetch(:value))
    end

    def parse_boolean
      token = @tokens.shift
      BooleanNode.new(token[:type] == :TRUE)
    end

    def parse_none
      consume(:NONE)
      VarRefNode.new("null")
    end

    def parse_var_ref
      VarRefNode.new(consume(:IDENTIFIER).fetch(:value))
    end

    def parse_integer
      IntegerNode.new(consume(:INTEGER).fetch(:value).to_i)
    end

    def parse_call
      name = consume(:IDENTIFIER).fetch(:value)
      arg_exprs = parse_args
      if name == "super" && peek(:DOT)
        consume(:DOT)
        member = consume(:IDENTIFIER).fetch(:value)
        if member == "__init__"
          inner_args = parse_args
          return SuperNode.new(inner_args)
        end
      end

      if name.match?(/\A[A-Z]/)
        MethodCallNode.new(VarRefNode.new(name), "new", arg_exprs)
      else
        CallNode.new(name, arg_exprs)
      end
    end

    private

    def consume(expected_type)
      token = @tokens.shift
      if !token || token[:type] != expected_type
        raise RV::CompileError.new(
          "Expected token #{expected_type}, but got #{token ? token[:type].inspect : 'EOF'}",
          filename: @filename,
          line: token ? token[:line] : nil,
          column: token ? token[:column] : nil,
          code: @code
        )
      end
      token
    end

    def peek(expected_type, offset = 0)
      @tokens[offset] && @tokens[offset][:type] == expected_type
    end

    def peek_type(offset = 0)
      @tokens[offset] && @tokens[offset][:type]
    end
  end
end
