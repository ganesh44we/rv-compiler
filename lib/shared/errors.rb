module RV
  class CompileError < StandardError
    attr_reader :message, :filename, :line, :column, :code

    def initialize(message, filename: nil, line: nil, column: nil, code: nil)
      @message = message
      @filename = filename
      @line = line
      @column = column
      @code = code
      super(message)
    end

    # Generate a visual code snippet with a caret ^ pointing to the error
    def visual_snippet
      return "" unless @code && @line

      lines = @code.lines
      target_line = lines[@line - 1]
      return "" unless target_line

      snippet = "\n  #{@line} | #{target_line.rstrip}\n"
      if @column
        indent = " " * (@line.to_s.length + 3 + @column - 1)
        snippet += "    | #{indent}^\n"
      end
      snippet
    end

    def full_report
      report = "[RV Compile Error] #{@message}\n"
      report += "  at #{@filename}:#{@line}:#{@column}" if @filename && @line && @column
      report += visual_snippet
      report
    end
  end
end
