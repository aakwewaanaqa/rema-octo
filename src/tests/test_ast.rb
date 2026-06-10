# frozen_string_literal: true

require "minitest/autorun"
require "pp"
require_relative "../oppl/shared/string_consumer"
require_relative "../oppl/shared/token_consumer"
require_relative "../oppl/tokenize"
require_relative "../oppl/ast"

class TestAST < Minitest::Test
  def test_flow_basic
    sc = StringConsumer.new 'a |> b'
    tokens = Tokenize::TOKENIZE.(sc)
    tc = TokenConsumer.new tokens
    flow = Ast::AstFlowResult.new tc,{}

    pp flow.next(Ast::EAT_NAME).data
  end
end