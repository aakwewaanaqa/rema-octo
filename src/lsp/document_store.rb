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

  end
end
