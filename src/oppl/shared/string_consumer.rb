class StringConsumer
  attr_reader :literaling

  def initialize(str)
    @str = str
    @index = -1         # 目前讀取位置（-1 表示尚未開始）
    @escaping = false
    @literaling = false # 目前在字串字面值內時記錄開頭引號（'、"、`），否則 false
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
end