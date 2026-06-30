module Lsp
  class Handler
    def initialize(store)
      @store = store
    end

    def handle(request)
      method = request["method"]
      id     = request["id"]
      params = request["params"] || {}

      case method
      when "initialize"
        respond(id, {
          capabilities: {
            textDocumentSync: 1,
            hoverProvider: true,
            semanticTokensProvider: {
              legend: {
                tokenTypes: ["keyword", "string", "variable", "regexp"],
                tokenModifiers: []
              },
              full: true
            }
          }
        })

      when "initialized"
        nil

      when "textDocument/didOpen"
        uri  = params.dig("textDocument", "uri")
        text = params.dig("textDocument", "text")
        @store.update(uri, text)
        nil

      when "textDocument/didChange"
        uri  = params.dig("textDocument", "uri")
        text = params.dig("contentChanges", 0, "text") ||
               params.dig("textDocument", "text")
        @store.update(uri, text)
        nil

      when "textDocument/hover"
        uri = params.dig("textDocument", "uri")
        # LSP uses 0-based; our AST uses 1-based
        line = params.dig("position", "line").to_i + 1
        col  = params.dig("position", "character").to_i + 1

        node = @store.node_at(uri, line, col)
        if node
          respond(id, {
            contents: {
              kind: "markdown",
              value: "**#{node.name}**\nargs: `#{node.args.inspect}`"
            }
          })
        else
          respond(id, nil)
        end

      when "textDocument/semanticTokens/full"
        uri = params.dig("textDocument", "uri")
        respond(id, { data: @store.semantic_tokens(uri) })

      when "shutdown"
        respond(id, nil)

      when "exit"
        exit(0)

      else
        nil
      end
    end

    private

    def respond(id, result)
      return nil if id.nil?
      { "id" => id, "result" => result }
    end
  end
end
