# frozen_string_literal: true

require "minitest/autorun"
require_relative "../src/src"

class TestTokenizeLine < Minitest::Test
  include Oppl::Tokenize
  def test_single_token
    assert_equal ["word"], split_the_text_by_space("word")
  end

  def test_multiple_tokens
    assert_equal ["foo", "bar", "baz"], split_the_text_by_space("foo bar baz")
  end

  def test_quoted_string_with_space
    assert_equal ["regex", "'hello world'"], split_the_text_by_space("regex 'hello world'")
  end

  def test_quoted_string_is_kept_intact
    assert_equal ["scope", "<", ">:rec"], split_the_text_by_space("scope < >:rec")
  end

  def test_extra_spaces_ignored
    assert_equal ["foo", "bar"], split_the_text_by_space("foo  bar")
  end

  def test_empty_string
    assert_equal [], split_the_text_by_space("")
  end

  def test_only_spaces
    assert_equal [], split_the_text_by_space("   ")
  end
end

class TestSplitByDelimiter < Minitest::Test
  include Oppl::Tokenize
  def test_splits_by_colon
    assert_equal ["foo", "bar", "baz"], split_the_text_by_delimiter("foo:bar:baz", ":")
  end

  def test_splits_by_pipe
    assert_equal ["foo", "bar"], split_the_text_by_delimiter("foo|>bar", "|>")
  end

  def test_no_delimiter_returns_whole_string
    assert_equal ["foo"], split_the_text_by_delimiter("foo", ":")
  end

  def test_quoted_string_ignores_delimiter
    assert_equal ["foo", "'a:b'"], split_the_text_by_delimiter("foo:'a:b'", ":")
  end

  def test_empty_string_returns_empty
    assert_equal [], split_the_text_by_delimiter("", ":")
  end

  def test_delimiter_at_end
    assert_equal ["foo", "bar"], split_the_text_by_delimiter("foo:bar:", ":")
  end
end
