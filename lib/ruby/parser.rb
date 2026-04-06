require_relative '../shared/nodes'
require_relative '../shared/errors'

module Ruby
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
      else
        parse_expr
      end
    end

    def parse_class
      consume(:CLASS)
      name = consume(:IDENTIFIER).fetch(:value)
      parent_name = nil
      if peek(:LT)
        consume(:LT)
        parent_name = consume(:IDENTIFIER).fetch(:value)
      end
      body = parse_block([:END])
      consume(:END)
      
      # Extract methods from body
      methods = body.nodes.select { |n| n.is_a?(DefNode) }
      ClassNode.new(name, methods, parent_name)
    end

    def parse_def
      consume(:DEF)
      name = consume(:IDENTIFIER).fetch(:value)
      arg_names = parse_arg_names
      body = parse_block([:END, :RESCUE, :ENSURE])
      
      # Consume the terminator
      if peek(:END)
        consume(:END)
      elsif peek(:RESCUE) || peek(:ENSURE)
        # These will be handled if we were doing full method-begin-rescue
        # For our compiler, we expect methods to end with 'end'
        consume_any([:RESCUE, :ENSURE, :END])
      end
      
      DefNode.new(name, arg_names, body)
    end

    def parse_arg_names
      # Ruby methods can have optional parentheses
      if peek(:OPAREN)
        consume(:OPAREN)
        arg_names = []
        if peek(:IDENTIFIER)
          arg_names << consume(:IDENTIFIER).fetch(:value)
          while peek(:COMMA)
            consume(:COMMA)
            arg_names << consume(:IDENTIFIER).fetch(:value)
          end
        end
        consume(:CPAREN)
        return arg_names
      elsif peek(:IDENTIFIER) && !peek(:DOT, 1) && !peek(:ASSIGN, 1)
        # Simple single arg without parens
        return [consume(:IDENTIFIER).fetch(:value)]
      else
        return []
      end
    end

    def parse_block(terminators)
      terminators = [terminators].flatten
      nodes = []
      while @tokens.any? && !terminators.any? { |t| peek(t) }
        nodes << parse_expr
      end
      BlockNode.new(nodes)
    end

    def parse_expr
      if peek(:DEF)
        parse_def
      elsif peek(:CLASS)
        parse_class
      elsif (peek(:IDENTIFIER) || peek(:INSTANCE_VAR)) && peek(:ASSIGN, 1)
        parse_assignment
      elsif (peek(:IDENTIFIER) || peek(:INSTANCE_VAR)) && peek(:DOT, 1) && peek(:ASSIGN, 2)
        parse_assignment
      elsif peek(:IF)
        parse_if
      elsif peek(:WHILE)
        parse_while
      elsif peek(:MATCH)
        parse_match
      elsif peek(:BEGIN)
        parse_begin
      elsif peek(:RAISE)
        parse_raise
      elsif peek(:REQUIRE)
        parse_require
      else
        parse_binary_expr
      end
    end

    def parse_assignment
      left = if peek(:INSTANCE_VAR)
        parse_instance_var
      elsif peek(:IDENTIFIER) && peek(:DOT, 1)
        parse_access
      else
        var_name = consume(:IDENTIFIER).fetch(:value)
        VarRefNode.new(var_name)
      end
      
      consume(:ASSIGN)
      right = parse_expr
      AssignNode.new(left, right)
    end

    def parse_require
      consume(:REQUIRE)
      module_name = consume(:STRING).fetch(:value).gsub('"', '')
      alias_name = nil
      alias_name = "np" if module_name == "numpy"
      alias_name = "pd" if module_name == "pandas"
      ImportNode.new(module_name, alias_name)
    end

    def parse_begin
      consume(:BEGIN)
      body = parse_block([:RESCUE, :ENSURE, :END])
      rescue_body = nil
      ensure_body = nil
      
      if peek(:RESCUE)
        consume(:RESCUE)
        rescue_body = parse_block([:ENSURE, :END])
      end
      
      if peek(:ENSURE)
        consume(:ENSURE)
        ensure_body = parse_block(:END)
      end
      
      consume(:END)
      RescueNode.new(body, rescue_body, ensure_body)
    end

    def parse_raise
      consume(:RAISE)
      if peek(:OPAREN, 1) || peek(:STRING) || peek(:IDENTIFIER)
        value = parse_expr
      else
        value = StringNode.new('"Error"')
      end
      RaiseNode.new(value)
    end

    def parse_match
      consume(:MATCH)
      value = parse_expr
      cases = []
      while @tokens.any? && !peek(:END)
        if peek(:CASE)
          consume(:CASE)
          pattern = parse_primary
          consume(:ARROW)
          result = parse_expr
          cases << [pattern, result]
        else
          break
        end
      end
      consume(:END)
      MatchNode.new(value, cases)
    end

    def parse_if
      consume(:IF)
      condition = parse_expr
      then_body = parse_block([:ELSE, :END])
      else_body = nil
      if peek(:ELSE)
        consume(:ELSE)
        else_body = parse_block(:END)
      end
      consume(:END)
      IfNode.new(condition, then_body, else_body)
    end

    def parse_while
      consume(:WHILE)
      condition = parse_expr
      body = parse_block(:END)
      consume(:END)
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
            node = MethodCallNode.new(node, member, [])
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
      elsif peek(:INSTANCE_VAR)
        parse_instance_var
      elsif peek(:OBRACK)
        parse_array
      elsif peek(:OBRACE)
        parse_hash
      elsif peek(:SUPER)
        parse_super
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

    def parse_super
      consume(:SUPER)
      arg_exprs = []
      if peek(:OPAREN)
        arg_exprs = parse_args
      elsif peek(:IDENTIFIER) || peek(:INSTANCE_VAR) || peek(:INTEGER) || peek(:STRING) || peek(:TRUE) || peek(:FALSE)
        # Ruby unparenthesized super args (simplified)
        arg_exprs << parse_expr
        while peek(:COMMA)
          consume(:COMMA)
          arg_exprs << parse_expr
        end
      end
      SuperNode.new(arg_exprs)
    end

    def parse_tuple_or_paren
      consume(:OPAREN)
      if peek(:CPAREN)
        consume(:CPAREN)
        return TupleNode.new([])
      end
      expr = parse_expr
      consume(:CPAREN)
      expr
    end

    def parse_hash
      consume(:OBRACE)
      pairs = []
      while !peek(:CBRACE)
        if peek(:IDENTIFIER) || peek(:TYPE) || peek(:ALIAS)
          key = @tokens.shift[:value]
          consume(:COLON)
          val = parse_expr
          pairs << [key, val]
        elsif peek(:STRING)
          key = consume(:STRING).fetch(:value).gsub('"', '')
          if peek(:ARROW)
            consume(:ARROW)
          else
            consume(:COLON)
          end
          val = parse_expr
          pairs << [key, val]
        else
          break
        end
        consume(:COMMA) if peek(:COMMA)
      end
      consume(:CBRACE)
      HashNode.new(pairs)
    end

    def parse_args
      return [] unless peek(:OPAREN)
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
      BooleanNode.new(token[:type] == :TRUE || token[:type] == :true)
    end

    def parse_instance_var
      InstanceVarNode.new(consume(:INSTANCE_VAR).fetch(:value))
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
      
      if name.match?(/\A[A-Z]/)
        # Class instantiation in Ruby via .new
        if peek(:DOT) && peek(:IDENTIFIER, 1) && @tokens[1][:value] == "new"
          consume(:DOT)
          consume(:IDENTIFIER)
          inner_args = parse_args
          return MethodCallNode.new(VarRefNode.new(name), "new", inner_args)
        end
      end
      
      CallNode.new(name, arg_exprs)
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
