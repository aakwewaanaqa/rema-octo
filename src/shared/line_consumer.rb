module Shared
  class LineConsumer
    attr_writer :readable_pos_offset

    def initialize str
      @lines = /\R/.split str
      @index = -1
      @readable_pos_offset = ReadablePos.new
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

    def readable_pos
      return ((ReadablePos.new 1, 0) + @readable_pos_offset) if @index < 0
      (ReadablePos.new @index + 1, 0) + @readable_pos_offset
    end
  end
end