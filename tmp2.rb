class Parser
  def initialize(tokens)
    @tokens = tokens
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
    elsif peek(:ALIAS)
      parse_alias
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
    methods = []
    while @tokens.any? && !peek(:END)
      if peek(:DEF)
        methods << parse_def
      else
        @tokens.shift
      end
    end
    consume(:END)
    ClassNode.new(name, methods, parent_name)
  end

  def parse_alias
    consume(:ALIAS)
    new_name = consume(:IDENTIFIER).fetch(:value)
    consume(:ASSIGN)
    old_name = consume(:IDENTIFIER).fetch(:value)
    AliasNode.new(new_name, old_name)
  end

  def parse_def
    consume(:DEF)
    name = consume(:IDENTIFIER).fetch(:value)
    arg_names = parse_arg_names
    body = parse_block(:END)
    consume(:END)
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

  def parse_block(terminators)
    terminators = [terminators].flatten
    nodes = []
    while @tokens.any? && !terminators.any? { |t| peek(t) }
      nodes << parse_expr
    end
    BlockNode.new(nodes)
  end

  def parse_expr
    if (peek(:IDENTIFIER) || peek(:INSTANCE_VAR)) && peek(:ASSIGN, 1)
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
    else
      parse_binary_expr
    end
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
    value = parse_expr
    RaiseNode.new(value)
  end

  def parse_match
    consume(:MATCH)
    value = parse_expr
    cases = []
    while @tokens.any? && !peek(:END)
      consume(:CASE)
      pattern = parse_primary
      consume(:ARROW)
      result = parse_expr
      cases << [pattern, result]
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

  def parse_assignment
    if peek(:INSTANCE_VAR)
      name_node = parse_instance_var
    else
      var_name = consume(:IDENTIFIER).fetch(:value)
      name_node = VarRefNode.new(var_name)
    end
    consume(:ASSIGN)
    value = parse_expr
    AssignNode.new(name_node, value)
  end

  def parse_binary_expr
    left = parse_access
    if [:PLUS, :MINUS, :STAR, :SLASH, :EQ, :NEQ, :LT, :GT, :LEQ, :GEQ].include?(peek_type)
      op = @tokens.shift[:type]
      right = parse_expr
      BinaryOpNode.new(op, left, right)
    else
      left
    end
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
    elsif peek(:LAMBDA)
      parse_lambda
    elsif peek(:OBRACK)
      parse_array
    elsif peek(:OBRACE)
      parse_hash
    elsif peek(:SUPER)
      parse_super
    elsif peek(:INSTANCE_VAR)
      parse_instance_var
    elsif peek(:IDENTIFIER) && peek(:OPAREN, 1)
      parse_call
    elsif peek(:IDENTIFIER)
      parse_var_ref
    elsif peek(:OPAREN)
      consume(:OPAREN)
      expr = parse_expr
      consume(:CPAREN)
      expr
    else
      tok = @tokens.first
      loc = tok ? "at line #{tok[:line]}, column #{tok[:column]}" : "at end of file"
      raise "Unexpected token #{tok ? tok[:type].inspect : 'EOF'} in parse_primary #{loc}"
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

  def parse_hash
    consume(:OBRACE)
    pairs = []
    if !peek(:CBRACE)
      loop do
        key_token = @tokens.shift
        if ![:IDENTIFIER, :TYPE, :ALIAS, :CLASS, :DEF, :IF, :MATCH].include?(key_token[:type])
           raise "Expected identifier or keyword as hash key, but got #{key_token[:type]} near #{@tokens[0..2].inspect}"
        end
        key = key_token[:value]
        consume(:COLON)
        value = parse_expr
        pairs << [key, value]
        break unless peek(:COMMA)
        consume(:COMMA)
      end
    end
    consume(:CBRACE)
    HashNode.new(pairs)
  end

  def parse_lambda
    consume(:LAMBDA)
    arg_names = parse_arg_names
    if peek(:OBRACE)
      consume(:OBRACE)
      body = parse_block(:CBRACE)
      consume(:CBRACE)
    else
      body = parse_expr
    end
    LambdaNode.new(arg_names, body)
  end

  def parse_string
    StringNode.new(consume(:STRING).fetch(:value))
  end

  def parse_boolean
    token = @tokens.shift
    BooleanNode.new(token[:type] == :TRUE)
  end

  def parse_super
    consume(:SUPER)
    arg_exprs = parse_args
    SuperNode.new(arg_exprs)
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
    CallNode.new(name, arg_exprs)
  end

  private

  def consume(expected_type)
    token = @tokens.shift
    if !token || token[:type] != expected_type
      loc = token ? "at line #{token[:line]}, column #{token[:column]}" : "at end of file"
      raise "Syntax Error: Expected token #{expected_type}, but got #{token ? token[:type].inspect : 'EOF'} #{loc}"
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

