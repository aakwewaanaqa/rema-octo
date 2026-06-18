# frozen_string_literal: true

require "minitest/autorun"
require_relative "../shared/readable_pos"
require_relative "../shared/string_consumer"
require_relative "../shared/line_consumer"
require_relative "../shared/token_consumer"
require_relative "../shared/tokenized_line_consumer"
require_relative "../shared/token"
require_relative "../shared/ast"
require_relative "../magical/tokenize"

class TestMagicalTokenize < Minitest::Test
  include Magical::Tokenize
  include Shared

  def types(txt)
    TOKENIZE.(txt).map(&:last)
  end

  def test_plain_line_produces_code_then_newline
    assert_equal [:code, :new_line], types("foo = 1")
  end

  def test_plain_line_preserves_full_code_text
    tokens = TOKENIZE.("foo = 1")
    assert_equal "foo = 1", tokens[0].text
  end

  def test_no_magic_comment_produces_no_identifier_tokens
    tokens = TOKENIZE.("foo bar baz")
    assert_empty tokens.select { |t| t.last == :identifier }
  end

  def test_hash_tilde_splits_code_from_comment
    tokens = TOKENIZE.("foo = 1 #~ bar")
    assert_equal "foo = 1 ", tokens[0].text
    assert_equal :code, tokens[0].last
  end

  def test_hash_tilde_tokenizes_identifiers
    tokens = TOKENIZE.("x #~ foo bar")
    ids = tokens.select { |t| t.last == :identifier }.map(&:text)
    assert_equal ["foo", "bar"], ids
  end

  def test_double_slash_tilde_splits_code_from_comment
    tokens = TOKENIZE.("x = 1 //~ hello")
    assert_equal "x = 1 ", tokens[0].text
  end

  def test_double_slash_tilde_tokenizes_identifiers
    tokens = TOKENIZE.("x //~ hello world")
    ids = tokens.select { |t| t.last == :identifier }.map(&:text)
    assert_equal ["hello", "world"], ids
  end

  def test_multiple_lines_produce_multiple_code_tokens
    tokens = TOKENIZE.("a\nb")
    code_tokens = tokens.select { |t| t.last == :code }
    assert_equal 2, code_tokens.length
    assert_equal "a", code_tokens[0].text
    assert_equal "b", code_tokens[1].text
  end

  def test_multiple_lines_each_end_with_newline
    assert_equal [:code, :new_line, :code, :new_line], types("a\nb")
  end

  def test_semicolon_in_magic_comment_is_tokenized
    tokens = TOKENIZE.("x #~ foo;bar")
    assert tokens.any? { |t| t.last == :semi_colon }
  end

  def test_question_mark_in_magic_comment_is_tokenized
    tokens = TOKENIZE.("x #~ foo?")
    assert tokens.any? { |t| t.last == :question_mark }
  end

  def test_exclamation_in_magic_comment_is_tokenized
    tokens = TOKENIZE.("x #~ foo!")
    assert tokens.any? { |t| t.last == :exclamation }
  end

  def test_literal_in_magic_comment_is_tokenized
    tokens = TOKENIZE.("x #~ 'hello world'")
    assert tokens.any? { |t| t.last == :literal }
  end
end
