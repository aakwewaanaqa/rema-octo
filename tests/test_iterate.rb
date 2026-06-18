require 'pp'
require 'minitest/autorun'
require_relative '../src/src'

class TestIterate < Minitest::Test
  include Oppl::Tokenize
  include Oppl::Ast
  include Oppl::Ast::Instr
  include Oppl::Iterate

  def make_node str
    tc = Shared::TokenConsumer.new(TOKENIZE.(Shared::StringConsumer.new(str)))
    flow = AstFlowResult.new(tc, {})
    EAT_INSTR.(false, flow)[:instr]
  end

  def test_iterate
    node = make_node "a |> b |> c \n d"
    iterate node 
  end
end