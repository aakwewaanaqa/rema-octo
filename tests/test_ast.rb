# frozen_string_literal: true

require "minitest/autorun"
require "pp"
require_relative "../src/src"

class TestAST < Minitest::Test
  include Oppl::Tokenize
  include Oppl::Ast
  include Oppl::Ast::Instr

  def make_flow str
    tc = Shared::TokenConsumer.new(TOKENIZE.(Shared::StringConsumer.new(str)))
    AstFlowResult.new(tc, {})
  end

  # NAME_SUB

  def test_name_sub_collects_same_line_names
    names = []
    make_flow('a b c d')
      .pipe(EAT_NAME)
      .pipe(NAME_SUB.(names))
    assert_equal ['b', 'c', 'd'], names.map(&:text)
  end

  def test_name_sub_stops_at_newline
    names = []
    make_flow("a b\nc")
      .pipe(EAT_NAME)
      .pipe(NAME_SUB.(names))
    assert_equal ['b'], names.map(&:text)
  end

  def test_name_sub_empty_when_no_more_names
    names = []
    make_flow('a')
      .pipe(EAT_NAME)
      .pipe(NAME_SUB.(names))
    assert_equal [], names
  end

  # ARG_SUB

  def test_arg_sub_parses_name_and_args
    node = InstrNode.new
    make_flow('foo a b c')
      .pipe(ARG_SUB.(node))
    assert_equal 'foo', node.name
    assert_equal ['a', 'b', 'c'], node.args.map(&:text)
  end

  def test_arg_sub_no_args
    node = InstrNode.new
    make_flow('foo')
      .pipe(ARG_SUB.(node))
    assert_equal 'foo', node.name
    assert_equal [], node.args
  end

  def test_arg_sub_stops_args_at_newline
    node = InstrNode.new
    make_flow("foo a\nb")
      .pipe(ARG_SUB.(node))
    assert_equal 'foo', node.name
    assert_equal ['a'], node.args.map(&:text)
  end

  # MOD_SUB

  def test_mod_sub_single_modifier
    node = InstrNode.new
    make_flow('when x y')
      .pipe(MOD_SUB.(node))
    assert_equal({ when: ['x', 'y'] }, node.mods.transform_values { |v| v.map(&:text) })
  end

  def test_mod_sub_multiple_modifiers
    node = InstrNode.new
    make_flow('when x : else z w')
      .pipe(MOD_SUB.(node))
    assert_equal({ when: ['x'], else: ['z', 'w'] }, node.mods.transform_values { |v| v.map(&:text) })
  end

  def test_mod_sub_stops_at_newline
    node = InstrNode.new
    make_flow("when x\nelse y")
      .pipe(MOD_SUB.(node))
    assert_equal({ when: ['x'] }, node.mods.transform_values { |v| v.map(&:text) })
  end

  # REST_PART_SUB

  def test_REST_PART_SUB_block
    result = make_flow('foo { bar }').pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'foo', result[:instr].name
    assert_equal 'bar', result[:instr].block_instr.name
  end

  def test_REST_PART_SUB_pipe
    result = make_flow('foo |> bar').pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'foo', result[:instr].name
    assert_equal 'bar', result[:instr].pipe_instr.name
  end

  def test_REST_PART_SUB_pipe_chain_next_instr_belongs_to_head
    result = make_flow("a |> b |> c\nd").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'a', result[:instr].name
    assert_equal 'b', result[:instr].pipe_instr.name
    assert_equal 'c', result[:instr].pipe_instr.pipe_instr.name
    assert_nil result[:instr].pipe_instr.next_instr
    assert_nil result[:instr].pipe_instr.pipe_instr.next_instr
    assert_equal 'd', result[:instr].next_instr.name
  end

  def test_REST_PART_SUB_block_then_pipe
    result = make_flow('a |> b { c } |> d').pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'a', result[:instr].name
    assert_equal 'b', result[:instr].pipe_instr.name
    assert_equal 'c', result[:instr].pipe_instr.block_instr.name
    assert_equal 'd', result[:instr].pipe_instr.pipe_instr.name
  end

  def test_REST_PART_SUB_next_instr
    result = make_flow("foo\nbar").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'foo', result[:instr].name
    assert_equal 'bar', result[:instr].next_instr.name
  end

  def test_full_eat_instr
    result = make_flow("islands:start_with '#!'").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'islands', result[:instr].name
    assert_equal "'#!'", result[:instr].mods[:start_with][0].text
  end

  # start_pos

  def test_instr_node_has_start_pos
    result = make_flow('foo bar').pipe(EAT_INSTR.(false))
    assert result.ok?
    pos = result[:instr].start_pos
    assert_equal 1, pos.line
    assert_equal 1, pos.column
  end

  def test_instr_node_next_instr_has_correct_start_pos
    result = make_flow("foo\nbar").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 1, result[:instr].start_pos.line
    assert_equal 2, result[:instr].next_instr.start_pos.line
    assert_equal 1, result[:instr].next_instr.start_pos.column
  end

  def test_instr_node_pipe_instr_has_correct_start_pos
    result = make_flow('foo |> bar').pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 1, result[:instr].start_pos.line
    assert_equal 1, result[:instr].start_pos.column
    assert_equal 1, result[:instr].pipe_instr.start_pos.line
    assert_equal 8, result[:instr].pipe_instr.start_pos.column
  end

  # node_at

  def test_node_at_finds_node_at_position
    result = make_flow('foo').pipe(EAT_INSTR.(false))
    assert_equal 'foo', result[:instr].node_at(1, 1)&.name
    assert_equal 'foo', result[:instr].node_at(1, 3)&.name
  end

  def test_node_at_returns_nil_outside_range
    result = make_flow('foo').pipe(EAT_INSTR.(false))
    assert_nil result[:instr].node_at(1, 4)
    assert_nil result[:instr].node_at(2, 1)
  end

  def test_node_at_traverses_next_instr
    result = make_flow("foo\nbar").pipe(EAT_INSTR.(false))
    assert_equal 'foo', result[:instr].node_at(1, 1)&.name
    assert_equal 'bar', result[:instr].node_at(2, 1)&.name
  end

  def test_node_at_traverses_pipe_instr
    result = make_flow('foo |> bar').pipe(EAT_INSTR.(false))
    assert_equal 'foo', result[:instr].node_at(1, 1)&.name
    assert_equal 'bar', result[:instr].node_at(1, 8)&.name
  end

  def test_node_at_traverses_block_instr
    result = make_flow('foo { bar }').pipe(EAT_INSTR.(false))
    assert_equal 'foo', result[:instr].node_at(1, 1)&.name
    assert_equal 'bar', result[:instr].node_at(1, 7)&.name
  end

  # multiline pipe

  def test_pipe_on_next_line_is_parsed_as_pipe_instr
    result = make_flow("foo\n|> bar").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'foo', result[:instr].name
    assert_equal 'bar', result[:instr].pipe_instr&.name
    assert_nil result[:instr].next_instr
  end

  def test_pipe_on_next_line_with_indent
    result = make_flow("foo\n   |> bar").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'bar', result[:instr].pipe_instr&.name
  end

  def test_chained_pipe_on_multiple_lines
    result = make_flow("foo\n|> bar\n|> baz").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'bar', result[:instr].pipe_instr&.name
    assert_equal 'baz', result[:instr].pipe_instr&.pipe_instr&.name
  end

  def test_multiline_pipe_then_next_instr
    result = make_flow("foo\n|> bar\nnext").pipe(EAT_INSTR.(false))
    assert result.ok?
    assert_equal 'bar', result[:instr].pipe_instr&.name
    assert_equal 'next', result[:instr].next_instr&.name
  end

  def test_node_at_multiline_pipe
    result = make_flow("foo\n|> bar").pipe(EAT_INSTR.(false))
    assert_equal 'foo', result[:instr].node_at(1, 1)&.name
    assert_equal 'bar', result[:instr].node_at(2, 4)&.name
  end
end
