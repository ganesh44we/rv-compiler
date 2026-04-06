module Shared
  class Optimizer
    def initialize(code)
      @code = code
    end

    def optimize
      optimized = @code.dup

      # 1. PEERPHOLE: i = i + 1  => i++
      # Using regex to catch simple increment/decrement patterns
      optimized.gsub!(/([a-zA-Z0-9_]+)\s*=\s*\1\s*\+\s*1\s*;/, '\1++;')
      optimized.gsub!(/([a-zA-Z0-9_]+)\s*=\s*\1\s*-\s*1\s*;/, '\1--;')

      # 2. REDUNDANCY: !! simplification
      # Simplify !!true/!!false and multiple negations
      optimized.gsub!(/!!true/, 'true')
      optimized.gsub!(/!!false/, 'false')

      # 3. DEAD CODE: String-only statements (detected as comments/docs)
      # These often appear in Ruby-to-JS if docstrings are used, or as relics of certain nodes
      # Format: "some string"; -> (remove if not followed by return or assignment)
      # We only remove them if they are on their own line with a semicolon
      optimized.gsub!(/^\s*"[^"]*";\s*$/, '')

      # 4. CONSTANT FOLDING (Basic)
      # 2 + 2 -> 4
      optimized.gsub!(/(\d+)\s*\+\s*(\d+)/) { ($1.to_i + $2.to_i).to_s }
      optimized.gsub!(/(\d+)\s*\*\s*(\d+)/) { ($1.to_i * $2.to_i).to_s }

      # 5. SEMICOLON CLEANUP
      # Remove double semicolons ;;
      optimized.gsub!(/;;+/, ';')
      
      # 6. RETURN VALUE OPTIMIZATION
      # Some expressions like console.log return undefined, but we generate 'return console.log'
      # We can remove the return if it's not the intent of the function
      # (This is more structural, but a simple regex can catch many cases)
      # optimized.gsub!(/return\s+(console\.log\(.*\))/, '\1')

      optimized
    end
  end
end
