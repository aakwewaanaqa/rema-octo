require 'minitest/autorun'
require_relative '../src/src'

class TestEach < Minitest::Test
  include Oppl::Tokenize
  include Oppl::Ast
  include Oppl::Ast::Instr
  include Oppl::Iterate

  def make_node str
    tc = Shared::TokenConsumer.new(TOKENIZE.(Shared::StringConsumer.new(str)))
    flow = AstFlowResult.new(tc, {})
    EAT_INSTR.(false, flow)[:instr]
  end

  def run_scopes text, open_str, close_str, mods = {}
    Oppl::Instructions::Scopes.(
      [open_str, close_str], mods, text, Shared::Context.new
    )
  end

  # scopes

  def test_scopes_returns_all_matches
    result = run_scopes 'A[hello]B[world]C', '[', ']'
    assert_equal ['hello', 'world'], result
  end

  def test_scopes_single_match
    result = run_scopes 'A[hello]B', '[', ']'
    assert_equal ['hello'], result
  end

  def test_scopes_no_match
    result = run_scopes 'no brackets here', '[', ']'
    assert_equal [], result
  end

  def test_scopes_keep_head_keep_tail
    result = run_scopes 'A[hello]B[world]C', '[', ']', { keep_head: [], keep_tail: [] }
    assert_equal ['[hello]', '[world]'], result
  end

  # each

  def test_each_maps_array_through_block
    node = make_node 'each { txt "x" }'
    result = iterate(node, ['a', 'b', 'c'])
    assert_equal ['x', 'x', 'x'], result[:result]
  end

  def test_each_passes_item_as_val_to_block
    node = make_node 'each { var item }'
    result = iterate(node, ['foo', 'bar'])
    assert_equal ['foo', 'bar'], result[:result]
  end

  def test_each_empty_array
    node = make_node 'each { txt "x" }'
    result = iterate(node, [])
    assert_equal [], result[:result]
  end

  # scopes + each pipeline

  def test_scopes_piped_into_each
    node = make_node 'scopes "[" "]" |> each { var item }'
    result = iterate(node, 'A[hello]B[world]C')
    assert_equal ['hello', 'world'], result[:result]
  end
end
