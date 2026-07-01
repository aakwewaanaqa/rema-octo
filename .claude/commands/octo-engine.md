# Octo Engine：Oppl 與 Magical 設計說明

這份文件說明本專案兩個核心語言 **Oppl** 與 **Magical** 的設計意義、語法與協作方式。
閱讀本文後應能獨立撰寫 `.oppl` 腳本與 Magical 模板。

---

## 整體架構

```
[ .oppl 腳本 ]  ──執行──>  [ Oppl 引擎 ]
                               │
                  讀檔、萃取資料、設定 ctx.vars
                               │
                  macinterpret (橋接指令)
                               │
                        [ Magical 引擎 ]
                               │
                  逐行處理模板、替換 ctx.vars
                               │
                        [ 輸出檔案 ]
```

- **Oppl** 是「指揮官」：讀源碼、萃取資料、管理 context、控制流程。
- **Magical** 是「模板引擎」：把模板裡的佔位符換成 Oppl 設好的變數。
- **macinterpret** 是橋：一個 Oppl 指令，把字串值丟進 Magical 引擎執行。

---

## Oppl

### 執行單位：`.oppl` 檔

Oppl 是 pipeline 語言。每一行是一條指令，用 `|>` 把輸出接到下一條指令的輸入（`val`）。

### 語法

```oppl
指令名稱 arg1 arg2  mod1: mod2 arg:  { 子區塊 }  |> 下一個指令
```

| 元素 | 說明 |
|---|---|
| `arg1 arg2` | 位置引數（字串或 identifier） |
| `mod:` | 修飾符，形式為 `key: value` 或單純 `key:` |
| `{ ... }` | block，產生子 context，裡面可再有完整 pipeline |
| `\|>` | pipe：把前一個指令的回傳值當作下一個的 `val` |
| 換行 | 新的頂層指令（sequential，不是 pipe） |

### 所有內建指令

| 指令 | 作用 |
|---|---|
| `read path` | 讀取檔案，回傳檔案內容字串。可帶 block，block 內可用 `val` |
| `write path` | 把 `val` 寫入 `path`。`mode:` mod 可為 `replace`（預設）或 `append` |
| `find regex` | 在當前目錄找符合 regex 的檔名，回傳陣列 |
| `ls` | 列出當前目錄，回傳陣列 |
| `cd path` | 切換工作目錄 |
| `var name` | 把 `val` 存進 `ctx.vars[:name]`，同時回傳 `val`；無 val 時回傳 `ctx.vars[:name]` |
| `vars` | 把 `val`（.env 格式字串）解析後批次寫入 `ctx.vars`，回傳整個 `ctx.vars` |
| `txt "string"` | 回傳字串字面值（忽略 `val`） |
| `scope open close` | 從 `val` 中擷取第一個 `open`…`close` 之間的文字。支援 `/regex/` 格式，`keep_head:` / `keep_tail:` 保留邊界 |
| `scopes open close` | 與 `scope` 相同，但回傳**所有**配對的陣列（`Array<String>`）。支援相同 modifier |
| `each { ... }` | 對 `val`（陣列）的每個元素執行 block，回傳結果陣列。block 內可用 pipe chain |
| `line n` | 從 `val` 取出第 n 行（0-based） |
| `exit` | 結束執行 |
| `magical/macinterpret` | 把 `val`（字串）當作 Magical 模板執行，注入當前 ctx |

### 範例

```oppl
read "server/DailyMissionController.cs"
|> scope "//#" "//#"
|> var template_section

read "templates/client_api.cs"
|> magical/macinterpret
|> write "client/DailyMissionApi.cs"
```

---

## Magical

### 執行方式

Magical 逐行處理文字。每一行分為兩部分：

```
<程式碼部分>   //~ <指令部分>
```

- `//~` 或 `#~` 為觸發符號（支援兩種，適用不同語言）。
- 程式碼部分不動，指令部分決定這行要不要輸出、如何替換。

### 指令語法

指令寫在 `//~` 之後，可用 `;` 串接。

| 寫法 | 語意 |
|---|---|
| `rp var1 var2` | 把行內出現的 `var1`、`var2` 文字替換為 ctx 中同名變數的值（`.sub`，每次只換第一個） |
| `var1 !` | **rm_if_absent**：若 `var1` 不在 ctx → 整行刪除（回傳 nil）；若在 → 繼續 |
| `var1 ?` | **next_if_present**：若 `var1` 不在 ctx → 停止後續所有行的輸出（`:stop`）；若在 → 繼續 |
| `instr1 ; instr2` | 串接：先執行 `instr1`，結果再傳給 `instr2` |

### 三種指令的差異

| 指令 | var 不存在 | var 存在 | 影響範圍 |
|---|---|---|---|
| `rp` | 不替換（var 不在 ctx，字串不變） | 替換文字 | 只此行 |
| `var !` | 刪此行，繼續後面 | 繼續（next instr） | 只此行 |
| `var ?` | `:stop`，後面全不輸出 | 繼續（next instr） | 此行以後全部 |

### 實際範例（example_2.cs）

```csharp
public class name_controllerController //~rp name_controller
{
    //#
    public static async UniTask<type_return> str_endpoint( //~rp type_return ; rp str_endpoint
        type_dto dto,                                      //~type_dto ! rp type_dto
        Ct ct = default) =>
        await new RequestBuilder()
            .AddQuery(dto)
            .SetMethod("str_method")                       //~rp str_method
            .SetEndpoint("str_endpoint")                   //~rp str_endpoint
            .AddAuthorization()
            .Send<type_return>(ct);                        //~rp type_return
    //#
}
```

| 行 | 指令 | 說明 |
|---|---|---|
| `name_controllerController` | `rp name_controller` | 把 `name_controller` 換成 ctx 裡的值，例如 `DailyMission` |
| `UniTask<type_return> str_endpoint(` | `rp type_return ; rp str_endpoint` | 先換 type_return，再換 str_endpoint |
| `type_dto dto,` | `type_dto ! rp type_dto` | 無 dto → 整行刪除（GET 無參數的情況）；有 dto → 替換型別名 |
| `.SetMethod("str_method")` | `rp str_method` | 換成 `"GET"` 或 `"POST"` |
| `.SetEndpoint("str_endpoint")` | `rp str_endpoint` | 換成完整 endpoint 路徑 |

### `//#` 的用途

`//#` 本身不是 Magical 指令（`//~` 才是），它是純字串標記，
供 Oppl 的 `scope "//#" "//#"` 指令用來截取模板中的重複單元（例如每個 method 的 block）。

---

## AST 位置追蹤（LSP 基礎）

### Token 位置

每個 `Token` 有 `readable_pos`（起始位置，1-based line/column）和 `end_pos`（結束位置，由 text 計算）：

```ruby
token.readable_pos  # => ReadablePos(line:1, col:1)
token.end_pos       # => ReadablePos(line:1, col:3)  # for "foo"
```

### InstrNode 位置

`InstrNode` 有 `start_pos`（name token 的起始位置），在 parse 時由 `ARG_SUB` 設定。

### node_at(line, col)

`InstrNode#node_at(line, col)` 根據 1-based 行列找出最接近的節點，遞迴走訪 `block_instr`、`pipe_instr`、`next_instr`：

```ruby
ast = EAT_INSTR.(false).(flow)[:instr]
node = ast.node_at(1, 8)  # => 找到 col 8 的指令節點
node.name                  # => "bar"（例如 "foo |> bar" 中）
```

---

## Oppl ↔ Magical 協作完整流程

```
1. Oppl 讀取服務端源碼（read）
2. Oppl 用 scope / line 萃取需要的片段
3. Oppl 用 var 把萃取結果存進 ctx.vars
   例：ctx.vars[:name_controller] = "DailyMission"
       ctx.vars[:type_return]     = "Response<List<DailyQuestDto>>"
       ctx.vars[:str_method]      = "GET"
       ctx.vars[:str_endpoint]    = "api/daily-missions/today"
       ctx.vars[:type_dto]        = nil  ← GET 無 body，不設定
4. Oppl 讀取模板（read "template.cs"）
5. magical/macinterpret 用 ctx 執行 Magical 模板
6. Oppl 把結果寫出（write）
```
