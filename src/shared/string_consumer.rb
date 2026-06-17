module Shared
  class StringConsumer
    attr_reader :literaling
    attr_reader :index
    attr_writer :readable_pos_offset

    def initialize str
      @str = str
      @index = -1         # 目前讀取位置（-1 表示尚未開始）
      @escaping = false
      @literaling = false # 目前在字串字面值內時記錄開頭引號（'、"、`），否則 false
      @readable_pos_offset = { line: 0, column: 0 }
    end

    # 目前字元是否被 \ 跳脫（連續偶數個 \ 視為互相抵消，不算跳脫）
    def peak_escaped?
      return false unless @literaling

      switch = false
      i = @index - 1
      while i >= 0 && @str[i] == '\\'
        switch = !switch
        i -= 1
      end

      return switch
    end

    def done?
      @index >= @str.length - 1
    end

    def rest
      return nil if done?
      @str[@index + 1..]
    end

    def sneak_peek
      return nil if done?
      return @str[@index + 1]
    end

    def match_sneak_peak candidates
      return nil if done?

      candidates.each do |pattern|
        return pattern if rest.start_with?(pattern)
      end

      return nil
    end

    def str_advance str
      return nil if done?
      return nil unless rest.start_with? str

      @index += str.length
      return str
    end

    def match_advance pattern
      return nil if done?
      _rest = rest
      match = pattern.match _rest
      to_s = match.to_s
      if _rest.start_with?(to_s)
        to_s.length.times { advance }
        return match
      end

      nil
    end

    # 前進一個字元，並更新 @literaling 狀態，回傳新位置的字元；超界回傳 nil
    def advance
      return nil if done?

      @index += 1
      peak = @str[@index]

      if !@literaling && (peak == "'" || peak == '"' || peak == '`')
        @literaling = peak
      elsif peak == @literaling && !peak_escaped?
        @literaling = false
      end

      return peak
    end

    def readable_pos
      return { line: 1 + @readable_pos_offset[:line], column: 1 + @readable_pos_offset[:column] } if @index < 0

      line = 1 + @str[0..@index].count("\n")
      last_newline_index = @str.rindex("\n", @index) || -1
      column = @index - last_newline_index + 1
      return { line: line + @readable_pos_offset[:line], column: column + @readable_pos_offset[:column] }
    end
  end
end
