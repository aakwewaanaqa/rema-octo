class Ctx
  def initialize
    @source = String       # 完整源代碼字串，掃描過程中不變
    @pointer = 0           # 目前讀取位置（index into @source）
    @last_match = []       # 上一條指令捕捉到的字串，String array（regex 多 group 時有多個）
    @line = 0              # 目前行號（1-based）
    @col = 0               # 目前欄號（1-based）

    @vars = {}             # pipeline 執行中收集到的變數，key 為 var 名稱
    @last_node = nil       # scope:rec:split 解析出的樹狀節點，供 $ 導航指令使用
    @loop_index = 0        # 目前 loop 迭代次數，供 var '@' 注入索引用
    @returning = []        # sub/loop 內執行到 return 指令時設為 true，讓外層提早結束
    @soft_fail = false     # contains? 指令的可選模式：失敗時不報錯，只設此旗標
  end
end