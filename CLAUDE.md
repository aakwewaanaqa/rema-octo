# CLAUDE

這個專案是 `~/fs-projs/rema-gen-octo` 移植過來的，
我想要用 ruby 寫比較靈活！然後我會改掉架構，
所以記得要看兩邊專案的 `docs`。

## F# 專案命名規則問題注意

parse_block 應該是編譯 `{ }` 才對，比較符合我們講程式碼的通俗命名規則
通常都叫 `{ }` `block` 或是 `scope` 啊

parse_group 應該是編譯 `a |> b |> c` 才對，比較符合我們講程式碼的通俗命名規則
