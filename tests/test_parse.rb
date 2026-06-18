# frozen_string_literal: true

require "minitest/autorun"
require_relative "../src/src"

module ParseHelper
  include Parse

  def colon_token(str)
    parse_instr_colon_token(Shared::StringConsumer.new(str), {})
  end

  def instr_token(str, ctx = {})
    parse_instr_token(Shared::StringConsumer.new(str), ctx)
  end
end

# parse_instr_colon_token: 解析以 `:` 分隔的 colon chain
# 每個 node: { name:, args:, text:, next_instr_colon: }
class TestParseInstrColonToken < Minitest::Test
  include ParseHelper

  def test_simple_name
    t = colon_token("foo")
    assert_equal "foo", t[:name]
    assert_equal [],    t[:args]
    assert_nil          t[:next_instr_colon]
  end

  def test_name_with_args
    t = colon_token("foo bar baz")
    assert_equal "foo",          t[:name]
    assert_equal ["bar", "baz"], t[:args]
    assert_nil                   t[:next_instr_colon]
  end

  def test_single_colon_chain
    t = colon_token("foo:bar")
    assert_equal "foo", t[:name]
    assert_equal "bar", t[:next_instr_colon][:name]
    assert_nil          t[:next_instr_colon][:next_instr_colon]
  end

  def test_colon_with_args
    t = colon_token("foo:split ,")
    assert_equal "foo",   t[:name]
    assert_equal "split", t[:next_instr_colon][:name]
    assert_equal [","],   t[:next_instr_colon][:args]
  end

  def test_multiple_colons_chain
    t = colon_token("scope:split ,:rec")
    assert_equal "scope",  t[:name]
    next1 = t[:next_instr_colon]
    assert_equal "split",  next1[:name]
    assert_equal [","],    next1[:args]
    next2 = next1[:next_instr_colon]
    assert_equal "rec",    next2[:name]
    assert_equal [],       next2[:args]
    assert_nil             next2[:next_instr_colon]
  end

  def test_literal_string_not_split_on_colon
    t = colon_token("foo 'a:b'")
    assert_equal "foo",    t[:name]
    assert_equal ["'a:b'"], t[:args]
    assert_nil             t[:next_instr_colon]
  end

  def test_trailing_colon_appends_empty_node
    t = colon_token("foo:bar:")
    assert_equal "foo", t[:name]
    assert_equal "bar", t[:next_instr_colon][:name]
    assert_nil          t[:next_instr_colon][:next_instr_colon][:name]
  end
end

# parse_instr_token: 解析一整段指令（含換行、block、pipe）
# 回傳: { colon_tokens:, piped_instr_token:, next_instr_token:, block_token: }
class TestParseInstrToken < Minitest::Test
  include ParseHelper

  def test_single_instruction
    t = instr_token("foo")
    assert_equal "foo", t[:colon_tokens][:name]
    assert_nil t[:piped_instr_token]
    assert_nil t[:next_instr_token]
    assert_nil t[:block_token]
  end

  def test_colon_chain_inside_instruction
    t = instr_token("foo:bar:baz")
    assert_equal "foo", t[:colon_tokens][:name]
    assert_equal "bar", t[:colon_tokens][:next_instr_colon][:name]
    assert_equal "baz", t[:colon_tokens][:next_instr_colon][:next_instr_colon][:name]
  end

  def test_instruction_with_args_and_mods
    t = instr_token("scope < >:split ,:rec")
    ct = t[:colon_tokens]
    assert_equal "scope", ct[:name]
    assert_equal ["<", ">"], ct[:args]
    assert_equal "split", ct[:next_instr_colon][:name]
    assert_equal "rec",   ct[:next_instr_colon][:next_instr_colon][:name]
  end

  def test_next_instruction_on_newline
    t = instr_token("foo\nbar")
    assert_equal "foo", t[:colon_tokens][:name]
    assert_nil t[:piped_instr_token]
    assert_equal "bar", t[:next_instr_token][:colon_tokens][:name]
  end

  def test_three_instructions_across_lines
    t = instr_token("a\nb\nc")
    assert_equal "a", t[:colon_tokens][:name]
    assert_equal "b", t[:next_instr_token][:colon_tokens][:name]
    assert_equal "c", t[:next_instr_token][:next_instr_token][:colon_tokens][:name]
  end

  def test_block_content_accessible
    t = instr_token("foo {\nbar\n}")
    assert_nil t[:next_instr_token]
    bar_token = t[:block_token][:next_instr_token]
    assert_equal "bar", bar_token[:colon_tokens][:name]
  end

  def test_block_followed_by_next_instruction
    t = instr_token("foo {\ninner\n}\nnext")
    assert_equal "next", t[:next_instr_token][:colon_tokens][:name]
  end

  def test_pipe_same_line
    t = instr_token("foo |> bar")
    assert_equal "foo", t[:colon_tokens][:name]
    assert_equal "bar", t[:piped_instr_token][:colon_tokens][:name]
    assert_nil          t[:next_instr_token]
  end

  def test_unexpected_closing_brace_sets_error
    ctx = {}
    instr_token("}", ctx)
    assert ctx.key?(:error)
    assert_match /Unexpected/, ctx[:error][:message]
  end

  def test_closing_brace_stops_block
    t = instr_token("foo\n}", { inBlock: true })
    assert_equal "foo", t[:colon_tokens][:name]
    # `}` 會停止 block 的解析，next_instr_token 讀到空字串
    assert_nil t[:next_instr_token][:colon_tokens][:name]
  end
end
