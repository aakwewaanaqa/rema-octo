# frozen_string_literal: true

require "minitest/autorun"
require_relative "../src/src"

class TestIslands < Minitest::Test
  def call(str)
    Oppl::Islands.call(nil, nil, str, nil)
  end

  def test_single_island
    result = call("hello\nworld")
    assert_equal ["hello\nworld\n"], result
  end

  def test_two_islands_separated_by_empty_line
    result = call("a\nb\n\nc\nd")
    assert_equal ["a\nb\n", "c\nd\n"], result
  end

  def test_empty_string_returns_empty_array
    result = call("")
    assert_equal [], result
  end

  def test_multiple_empty_lines_treated_as_one_separator
    result = call("a\n\n\nb")
    assert_equal ["a\n", "b\n"], result
  end

  def test_trailing_empty_line_ignored
    result = call("a\nb\n")
    assert_equal ["a\nb\n"], result
  end

  def test_args_takes_priority_over_val
    result = Oppl::Islands.call(["from args"], nil, "from val", nil)
    assert_equal ["from args\n"], result
  end

  def test_val_used_when_args_nil
    result = Oppl::Islands.call(nil, nil, "from val", nil)
    assert_equal ["from val\n"], result
  end
end
