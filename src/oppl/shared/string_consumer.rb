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

  def sneak_peek!
    return nil if done?
    @str[@index + 1]
  end

  def match_sneak_peak? candidates
    return nil if done?

    candidates.each do |str|
      is_any_char = str == '_ANY_CHAR_'
      str_length = is_any_char ? 1 : str.length
      start_index = @index + 1
      next if str_length == 0
      next if (start_index + str_length) > @str.length

      is_match = is_any_char || (@str[start_index, str_length] == str)
      return true if is_match
    end

    return false
  end

  def match_and_advance! candidates
    return nil if done?

    candidates.each do |str|
      is_any_char = str == '_ANY_CHAR_'
      str_length = is_any_char ? 1 : str.length
      start_index = @index + 1
      next if str_length == 0
      next if (start_index + str_length) > @str.length

      is_match = is_any_char || (@str[start_index, str_length] == str)
      if is_match
        advance_step = str_length
        result = ''
        for _ in 0...advance_step do
          result += advance!
        end
        return result
      end
    end

    return nil
  end

  def advance_ahead_skip? str, skipped_characters
    i = @index + 1
    j = 0
    last_matched_i = nil
    while j < str.length && i < @str.length
      ch = @str[i]
      if skipped_characters.include?(ch)
        i += 1
        next
      end
      return false if ch != str[j]
      last_matched_i = i
      i += 1
      j += 1
    end
    return false unless j == str.length
    @index = last_matched_i
    true
  end

  # 前進一個字元，並更新 @literaling 狀態，回傳新位置的字元；超界回傳 nil
  def advance!
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
    line = 1 + @str[0..@index].count("\n")
    last_newline_index = @str.rindex("\n", @index) || -1
    column = @index - last_newline_index + 1
    return { line: line + @readable_pos_offset[:line], column: column + @readable_pos_offset[:column] }
  end
end