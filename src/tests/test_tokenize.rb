# frozen_string_literal: true

require "minitest/autorun"
require_relative "../oppl/shared/string_consumer"
require_relative "../oppl/tokenize"

class TestTokenizeLine < Minitest::Test
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
