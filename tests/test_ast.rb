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
    assert_equal ['b', 'c', 'd'], names
  end

  def test_name_sub_stops_at_newline
    names = []
    make_flow("a b\nc")
      .pipe(EAT_NAME)
      .pipe(NAME_SUB.(names))
    assert_equal ['b'], names
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
    assert_equal ['a', 'b', 'c'], node.args
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
    assert_equal ['a'], node.args
  end

  # MOD_SUB

  def test_mod_sub_single_modifier
    node = InstrNode.new
    make_flow('when x y')
      .pipe(MOD_SUB.(node))
    assert_equal({ when: ['x', 'y'] }, node.mods)
  end

  def test_mod_sub_multiple_modifiers
    node = InstrNode.new
    make_flow('when x : else z w')
      .pipe(MOD_SUB.(node))
    assert_equal({ when: ['x'], else: ['z', 'w'] }, node.mods)
  end

  def test_mod_sub_stops_at_newline
    node = InstrNode.new
    make_flow("when x\nelse y")
      .pipe(MOD_SUB.(node))
    assert_equal({ when: ['x'] }, node.mods)
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
    assert_equal "'#!'", result[:instr].mods[:start_with][0]
  end
end
