module Shared
  class TokenConsumer
    def initialize tokens
      @tokens = tokens
      @index = -1
    end

    def done?
      return @index >= @tokens.length - 1
    end

    def sneak_peek
      return nil if done?
      return @tokens[@index + 1]
    end

    def advance
      return nil if done?
      @index += 1
      return @tokens[@index]
    end
  end
end
