# frozen_string_literal: true

require "minitest/autorun"
require_relative "../oppl/shared/string_consumer"

class TestStringConsumer < Minitest::Test
  def test_advance_returns_chars_in_order
    c = StringConsumer.new("abc")
    assert_equal "a", c.advance!
    assert_equal "b", c.advance!
    assert_equal "c", c.advance!
  end

  def test_advance_returns_nil_at_end
    c = StringConsumer.new("a")
    c.advance!
    assert_nil c.advance!
  end

  def test_done
    c = StringConsumer.new("a")
    assert_equal false, c.done?
    c.advance!
    assert_equal true, c.done?
  end

  def test_literaling_tracks_single_quote
    c = StringConsumer.new("a'b'c")
    c.advance!                      # a
    assert_equal false, c.literaling
    c.advance!                      # '
    assert_equal "'", c.literaling
    c.advance!                      # b
    assert_equal "'", c.literaling
    c.advance!                      # '
    assert_equal false, c.literaling
  end

  def test_literaling_tracks_double_quote
    c = StringConsumer.new('"hi"')
    c.advance!
    assert_equal '"', c.literaling
  end

  def test_escaped_quote_does_not_close_literal
    c = StringConsumer.new("'a\\'b'")
    c.advance!   # '  → open
    c.advance!   # a
    c.advance!   # \
    c.advance!   # '  → escaped, should stay in literal
    assert_equal "'", c.literaling
  end

  def test_double_backslash_is_not_escape
    c = StringConsumer.new("'a\\\\'")
    c.advance!   # '  → open
    c.advance!   # a
    c.advance!   # \
    c.advance!   # \
    c.advance!   # '  → not escaped, should close literal
    assert_equal false, c.literaling
  end
end
