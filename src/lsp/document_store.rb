module Lsp
  class DocumentStore
    def initialize
      @docs = {}
    end

    def update(uri, text)
      sc = Shared::StringConsumer.new(text)
      tokens = Oppl::Tokenize::TOKENIZE.(sc)
      tc = Shared::TokenConsumer.new(tokens)
      flow = Shared::AstFlowResult.new(tc, {})
      result = Oppl::Ast::Instr::EAT_INSTR.(false).(flow)
      @docs[uri] = result[:instr]
    end

    def node_at(uri, line, col)
      @docs[uri]&.node_at(line, col)
    end

    TOKEN_TYPES = { keyword: 0, string: 1, variable: 2, regexp: 3, function: 4, number: 5 }

    def semantic_tokens(uri)
      root = @docs[uri]
      return [] unless root

      raw = collect_tokens(root)
      raw.sort_by! { |t| [t[:pos].line, t[:pos].column] }

      data = []
      prev_line = 0
      prev_col = 0
      raw.each do |t|
        line = t[:pos].line - 1  # 0-based
        col  = t[:pos].column - 1
        data.push(
          line - prev_line,
          line == prev_line ? col - prev_col : col,
          t[:length],
          TOKEN_TYPES[t[:type]] || 0,
          0
        )
        prev_line = line
        prev_col  = col
      end
      data
    end

    private

    def collect_tokens(node)
      return [] unless node
      klass = Oppl::Instructions.const_get(node.name.capitalize) rescue nil
      tokens = klass&.respond_to?(:lsp_tokens) ? klass.lsp_tokens(node) : []
      tokens +
        collect_tokens(node.block_instr) +
        collect_tokens(node.pipe_instr) +
        collect_tokens(node.next_instr)
    end

  end
end
