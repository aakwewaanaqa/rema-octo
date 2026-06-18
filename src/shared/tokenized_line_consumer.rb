module Shared
  class TokenizedLineConsumer 
    attr_reader :lines, :index

    def initialize tokens
      tc = TokenConsumer.new tokens
      lines = []
      cache = []
      while peak = tc.advance
        if peak.last == :new_line
          lines << cache # we also appends empty line
          cache = []
        end
        cache << peak
      end
      @lines = lines # Array[Array[Shared::Token]]
      @index = -1
    end

    def done?
      @index >= @lines.length
    end

    def sneak_peek
      return nil if done?
      @lines[@index + 1]
    end

    def advance
      return nil if done?
      @index += 1
      @lines[@index]
    end
  end
end