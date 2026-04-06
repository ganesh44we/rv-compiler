module Shared
  class Generator
    @@lib_cache = nil

    def generate(node, return_last: false)
      case node
      when ProgramNode
        @@lib_cache ||= File.read(File.expand_path('../rv_lib.js', __FILE__))
        @@lib_cache + "\n" + node.nodes.map { |n| generate(n) }.join("\n")
      when ImportNode
        module_name = node.module_name
        # Map Python/Ruby module names to RV shims
        case module_name
        when "numpy"   then module_name = "RV.numpy"
        when "pandas"  then module_name = "RV.pandas"
        when "requests" then module_name = "requests"   # Global in rv_lib.js
        when "git"      then module_name = "RV.Git"
        when "net/http" then module_name = "RV.Net"
        end
        node.alias_name ? "const #{node.alias_name} = #{module_name};" : "/* Imported #{module_name} */"
      when BlockNode
        generate_block(node, return_last: return_last)
      when ClassNode
        heritage = node.parent_name ? " extends #{node.parent_name}" : ""
        methods_code = node.methods.map { |m| generate_class_method(m) }.join("\n")
        "class #{node.name}#{heritage} {\n#{indent(methods_code)}\n}"
      when AliasNode
        "const #{node.new_name} = #{node.old_name};"
      when MatchNode
        generate_match(node, return_last: return_last)
      when WithNode
        generate_with(node)
      when RescueNode
        generate_rescue(node, return_last: return_last)
      when RaiseNode
        wrap_return(node, "throw new Error(#{generate(node.value)})", return_last)
      when DefNode
        args = node.arg_names.join(', ')
        "function #{node.name}(#{args}) {\n#{indent(generate(node.body, return_last: true))}\n}"
      when LambdaNode
        args = node.arg_names.join(', ')
        "((#{args}) => {\n#{indent(generate(node.body, return_last: true))}\n})"
      when IfNode
        res = "if (#{generate(node.condition)}) {\n#{indent(generate(node.then_body, return_last: return_last))}\n}"
        if node.else_body
          res += " else {\n#{indent(generate(node.else_body, return_last: return_last))}\n}"
        end
        res
      when WhileNode
        "while (#{generate(node.condition)}) {\n#{indent(generate(node.body, return_last: false))}\n}"
      when ForNode
        "for (let #{node.var} of #{generate(node.iterable)}) {\n#{indent(generate(node.body, return_last: false))}\n}"
      when AssignNode
        "#{generate(node.name)} = #{generate(node.value)}"
      when CallNode
        generate_builtin_call(node, return_last: return_last)
      when MethodCallNode
        if node.method == "new" && node.object.is_a?(VarRefNode)
          args = node.arg_exprs.map { |expr| generate(expr) }.join(', ')
          wrap_return(node, "new #{node.object.value}(#{args})", return_last)
        else
          method_name = map_method_name(node.method)
          args = node.arg_exprs.map { |expr| generate(expr) }.join(', ')
          wrap_return(node, "#{generate(node.object)}.#{method_name}(#{args})", return_last)
        end
      when IntegerNode
        wrap_return(node, node.value.to_s, return_last)
      when StringNode
        wrap_return(node, node.value, return_last)
      when BooleanNode
        wrap_return(node, node.value.to_s, return_last)
      when ArrayNode
        wrap_return(node, "[#{node.elements.map { |e| generate(e) }.join(', ')}]", return_last)
      when HashNode
        pairs = node.pairs.map { |k, v| "#{k}: #{generate(v)}" }.join(', ')
        wrap_return(node, "{#{pairs}}", return_last)
      when SetNode
         wrap_return(node, "new Set([#{node.elements.map { |e| generate(e) }.join(', ')}])", return_last)
      when TupleNode
         wrap_return(node, "Object.freeze([#{node.elements.map { |e| generate(e) }.join(', ')}])", return_last)
      when VarRefNode
        js_val = node.value == "self" ? "this" : node.value
        wrap_return(node, js_val, return_last)
      when InstanceVarNode
        wrap_return(node, node.value.sub('@', 'this.'), return_last)
      when SuperNode
        args = node.arg_exprs.map { |expr| generate(expr) }.join(', ')
        wrap_return(node, "super(#{args})", return_last)
      when AccessNode
        wrap_return(node, "#{generate(node.object)}.#{node.member}", return_last)
      when IndexNode
        wrap_return(node, "#{generate(node.object)}[#{generate(node.index)}]", return_last)
      when BinaryOpNode
        wrap_return(node, "#{generate(node.left, return_last: false)} #{operator_to_js(node.op)} #{generate(node.right, return_last: false)}", return_last)
      else
        raise "Unknown node type: #{node.class}"
      end
    end

    private

    def generate_builtin_call(node, return_last:)
      case node.name
      when "print"
        args = node.arg_exprs.map { |expr| generate(expr) }.join(', ')
        wrap_return(node, "console.log(#{args})", return_last)
      when "len"
        args = node.arg_exprs.map { |expr| generate(expr) }.join(', ')
        wrap_return(node, "(#{args}).length || (#{args}).size", return_last)
      when "range"
        n = generate(node.arg_exprs.first)
        wrap_return(node, "Array.from({length: #{n}}, (_, i) => i)", return_last)
      else
        args = node.arg_exprs.map { |expr| generate(expr) }.join(', ')
        wrap_return(node, "#{node.name}(#{args})", return_last)
      end
    end

    def generate_rescue(node, return_last:)
      res = "try {\n#{indent(generate(node.body, return_last: return_last))}\n}"
      
      if node.rescue_body
        res += " catch (e) {\n#{indent(generate(node.rescue_body, return_last: return_last))}\n}"
      elsif !node.ensure_body
        res += " catch (e) { throw e; }"
      end
      
      if node.ensure_body
        res += " finally {\n#{indent(generate(node.ensure_body, return_last: false))}\n}"
      end
      
      res
    end

    def generate_match(node, return_last:)
      val_name = "match_val_#{rand(1000)}"
      res = "((#{val_name}) => {\n"
      
      node.cases.each_with_index do |(pattern, body), i|
        condition = generate_match_condition(val_name, pattern)
        if i == 0
          res += indent("if (#{condition}) {\n#{indent("return " + generate(body, return_last: false) + ";")}\n}")
        elsif condition == "true"
          res += "\n" + indent("else {\n#{indent("return " + generate(body, return_last: false) + ";")}\n}")
          break 
        else
          res += "\n" + indent("else if (#{condition}) {\n#{indent("return " + generate(body, return_last: false) + ";")}\n}")
        end
      end
      
      res += "\n})(#{generate(node.value)})"
      wrap_return(node, res, return_last)
    end

    def generate_match_condition(val_name, pattern)
      case pattern
      when IntegerNode, StringNode, BooleanNode
        "#{val_name} === #{generate(pattern)}"
      when VarRefNode
        pattern.value == "_" ? "true" : "true"
      when ArrayNode
        conds = ["Array.isArray(#{val_name})", "#{val_name}.length === #{pattern.elements.length}"]
        pattern.elements.each_with_index do |elem, i|
          conds << generate_match_condition("#{val_name}[#{i}]", elem)
        end
        conds.join(" && ")
      when HashNode
        conds = ["typeof #{val_name} === 'object'", "#{val_name} !== null"]
        pattern.pairs.each do |k, v|
          conds << generate_match_condition("#{val_name}.#{k}", v)
        end
        conds.join(" && ")
      else
        "false"
      end
    end

    def generate_class_method(node)
      name = (node.name == "initialize" || node.name == "__init__") ? "constructor" : node.name
      clean_args = node.arg_names.reject { |a| a == "self" }.join(', ')
      "#{name}(#{clean_args}) {\n#{indent(generate(node.body, return_last: (name != "constructor")))}\n}"
    end

    def map_method_name(name)
      case name
      when "each" then "forEach"
      when "map" then "map"
      when "append", "push" then "push"
      when "strip", "trim" then "trim"
      when "lower", "downcase" then "toLowerCase"
      when "upper", "upcase" then "toUpperCase"
      when "extend" then "concat"
      when "add" then "add" # For Sets
      else name
      end
    end

    def wrap_return(node, code, return_last)
      if return_last
        "return #{code};"
      else
        code
      end
    end

    def generate_block(node, return_last:)
      return "" if node.nodes.empty?

      lines = node.nodes[0..-2].map { |n| "#{generate(n)};" }
      last_line = generate(node.nodes.last, return_last: return_last)
      
      if last_line.start_with?("return ") || node.nodes.last.is_a?(IfNode) || node.nodes.last.is_a?(WhileNode) || node.nodes.last.is_a?(DefNode) || node.nodes.last.is_a?(ClassNode) || node.nodes.last.is_a?(MatchNode) || node.nodes.last.is_a?(RescueNode)
        lines << last_line
      else
        lines << "#{last_line};"
      end
      
      lines.join("\n")
    end

    def generate_with(node)
      js = "{\n"
      if node.var_name
        js += indent("const #{node.var_name} = #{generate(node.expr)};") + "\n"
        js += indent("try {") + "\n"
        js += indent(indent(generate(node.body)))
        js += "\n" + indent("} finally {") + "\n"
        js += indent("  if (#{node.var_name} && typeof #{node.var_name}.close === 'function') #{node.var_name}.close();") + "\n"
        js += indent("}") + "\n"
      else
        tmp = "with_res_#{rand(1000)}"
        js += indent("const #{tmp} = #{generate(node.expr)};") + "\n"
        js += indent("try {") + "\n"
        js += indent(indent(generate(node.body)))
        js += "\n" + indent("} finally {") + "\n"
        js += indent("  if (#{tmp} && typeof #{tmp}.close === 'function') #{tmp}.close();") + "\n"
        js += indent("}") + "\n"
      end
      js += "}"
      js
    end

    def operator_to_js(op)
      case op
      when :PLUS then "+"
      when :MINUS then "-"
      when :STAR then "*"
      when :SLASH then "/"
      when :MODULO then "%"
      when :EQ then "==="
      when :NEQ then "!=="
      when :LT then "<"
      when :GT then ">"
      when :LEQ then "<="
      when :GEQ then ">="
      else raise "Unknown operator: #{op}"
      end
    end

    def indent(code)
      code.split("\n").map { |line| "  #{line}" }.join("\n")
    end
  end
end
