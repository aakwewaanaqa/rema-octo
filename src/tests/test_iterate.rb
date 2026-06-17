require 'pp'
require 'minitest/autorun'
require_relative '../oppl.rb'

class TestIterate < Minitest::Test
  include Tokenize
  include Ast
  include Ast::Instr
  include Iterate

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