module Shared
  class LineConsumer
    def initialize str
      @lines = /\R/.split str
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