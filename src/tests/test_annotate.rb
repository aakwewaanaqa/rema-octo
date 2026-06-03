# frozen_string_literal: true

require "minitest/autorun"
require_relative "../oppl/shared/string_consumer"
require_relative "../oppl/annotate"

class TestAnnotateLine < Minitest::Test
  def test_no_indent_no_pipe
    line = annotate_the_line("foo", 1)
    assert_equal 0,     line.indent
    assert_equal false, line.pipe
    assert_equal "foo", line.text
  end

  def test_space_indent_no_pipe
    line = annotate_the_line("  foo", 1)
    assert_equal 2,     line.indent
    assert_equal false, line.pipe
    assert_equal "foo", line.text
  end

  def test_no_indent_with_pipe
    line = annotate_the_line("|>foo", 1)
    assert_equal 0,     line.indent
    assert_equal true,  line.pipe
    assert_equal "foo", line.text
  end

  def test_space_indent_with_pipe
    line = annotate_the_line("  |>foo", 1)
    assert_equal 2,     line.indent
    assert_equal true,  line.pipe
    assert_equal "foo", line.text
  end

  def test_line_num_is_stored
    line = annotate_the_line("foo", 42)
    assert_equal 42, line.line_num
  end

  def test_tab_indent
    line = annotate_the_line("\tfoo", 1)
    assert_equal 1,     line.indent
    assert_equal false, line.pipe
    assert_equal "foo", line.text
  end
end
