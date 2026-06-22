module Shared
  class LiteralResolver
    def initialize pure_string_with_quote
      @raw = pure_string_with_quote
      @single = pure_string_with_quote&.start_with?("'")
      @double = pure_string_with_quote&.start_with?('"')

      if @double
        @template = pure_string_with_quote.gsub(/!\{(.*?)\}/) { "\#{\`#{$1}\`.chomp}" }
      end
    end

    def resolve(vars = {})
      return '' unless @raw
      return @raw[1..-2] if @single
      if @double
        b = binding
        vars.each { |k, v| b.local_variable_set(k, v) }
        eval(@template, b)
      else
        @raw
      end
    end
  end
end
