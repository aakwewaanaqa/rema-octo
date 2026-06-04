# frozen_string_literal: true

require "minitest/autorun"
require_relative "../oppl/shared/string_consumer"
require_relative "../oppl/tokenize"
require_relative "../oppl/parse"

class TestParseInstr < Minitest::Test
  def test_name_only
    instr = parse_instr("foo")
    assert_equal "foo", instr.name
    assert_equal [],    instr.params
    assert_equal ({}),  instr.mods
  end

  def test_name_with_params
    instr = parse_instr("foo bar baz")
    assert_equal "foo",          instr.name
    assert_equal ["bar", "baz"], instr.params
  end

  def test_mod_without_value
    instr = parse_instr("foo:rec")
    assert_equal "foo",        instr.name
    assert_equal [],           instr.params
    assert_equal ["rec", []], instr.mods.first
  end

  def test_mod_with_value
    instr = parse_instr("foo:split ,")
    assert_equal "foo",       instr.name
    assert_equal [","],       instr.mods["split"]
  end

  def test_complex_scope
    instr = parse_instr("scope < >:split ,:rec")
    assert_equal "scope",    instr.name
    assert_equal ["<", ">"], instr.params
    assert_equal [","],      instr.mods["split"]
    assert_equal [],         instr.mods["rec"]
  end

  def test_multiple_mods
    instr = parse_instr("foo:a:b:c")
    assert instr.mods.key?("a")
    assert instr.mods.key?("b")
    assert instr.mods.key?("c")
  end
end

class TestParseChain < Minitest::Test
  def test_single_instr
    result = parse_chain("foo")
    assert_instance_of Pipe,  result
    assert_equal "foo",       result.head.name
    assert_equal [],          result.tail
  end

  def test_two_instrs
    result = parse_chain("foo |> bar")
    assert_equal "foo", result.head.name
    assert_equal 1,     result.tail.length
    assert_equal "bar", result.tail[0].name
  end

  def test_three_instrs
    result = parse_chain("foo |> bar |> baz")
    assert_equal "foo", result.head.name
    assert_equal 2,     result.tail.length
    assert_equal "baz", result.tail[1].name
  end

  def test_head_with_params_and_mods
    result = parse_chain("scope < >:rec |> filter foo")
    assert_equal "scope",    result.head.name
    assert_equal ["<", ">"], result.head.params
    assert result.head.mods.key?("rec")
    assert_equal "filter",   result.tail[0].name
    assert_equal ["foo"],    result.tail[0].params
  end
end
