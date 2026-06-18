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
require_relative "../magical/ast"

class TestMagicalAstEatSeparator < Minitest::Test
  include Magical::Ast::Instr
  include Shared

  def make_flow(*token_specs)
    tokens = token_specs.map { |type, text| Token.new(type, text, nil) }
    tc = TokenConsumer.new(tokens)
    AstFlowResult.new(tc, {})
  end

  def test_detects_semicolon
    result = EAT_SEPERATOR.(make_flow([:semi_colon, ";"]))
    assert result[:ok]
    assert_equal :semi_colon, result[:last]
  end

  def test_detects_question_mark
    result = EAT_SEPERATOR.(make_flow([:question_mark, "?"]))
    assert result[:ok]
    assert_equal :question_mark, result[:last]
  end

  def test_detects_exclamation
    result = EAT_SEPERATOR.(make_flow([:exclamation, "!"]))
    assert result[:ok]
    assert_equal :exclamation, result[:last]
  end

  def test_rejects_non_separator
    result = EAT_SEPERATOR.(make_flow([:identifier, "foo"]))
    refute result[:ok]
  end

  def test_rejects_empty_stream
    result = EAT_SEPERATOR.(make_flow())
    refute result[:ok]
  end
end

class TestMagicalAstEatInstr < Minitest::Test
  include Magical::Ast::Instr
  include Shared

  def make_flow(*token_specs)
    tokens = token_specs.map { |type, text| Token.new(type, text, nil) }
    tc = TokenConsumer.new(tokens)
    AstFlowResult.new(tc, {})
  end

  def test_bare_instruction_sets_name_from_first_arg
    result = EAT_INSTR.(make_flow(
      [:identifier, "foo"],
      [:spaces, " "],
      [:identifier, "bar"]
    ))
    assert result[:ok]
    assert_equal "foo", result[:instr].name
    assert_equal ["bar"], result[:instr].args
  end

  def test_question_mark_sets_next_if_present
    result = EAT_INSTR.(make_flow(
      [:identifier, "foo"],
      [:question_mark, "?"]
    ))
    assert result[:ok]
    assert_equal :next_if_present, result[:instr].name
    assert_equal ["foo"], result[:instr].args
  end

  def test_exclamation_sets_rm_if_absent
    result = EAT_INSTR.(make_flow(
      [:identifier, "foo"],
      [:exclamation, "!"]
    ))
    assert result[:ok]
    assert_equal :rm_if_absent, result[:instr].name
    assert_equal ["foo"], result[:instr].args
  end

  def test_semicolon_chains_next_instr
    result = EAT_INSTR.(make_flow(
      [:identifier, "foo"],
      [:semi_colon, ";"],
      [:spaces, " "],
      [:identifier, "bar"]
    ))
    assert result[:ok]
    assert_equal "foo", result[:instr].name
    assert_equal [], result[:instr].args
    assert_equal "bar", result[:instr].next_instr.name
  end

  def test_empty_stream_is_not_ok
    result = EAT_INSTR.(make_flow())
    refute result[:ok]
    assert_nil result[:instr]
  end
end

class TestMagicalAstEatStat < Minitest::Test
  include Magical::Ast::Stat
  include Magical::Tokenize
  include Shared

  def make_tlc(txt)
    tokens = TOKENIZE.(txt)
    TokenizedLineConsumer.new(tokens)
  end

  def test_parses_code_from_first_token
    stat = EAT_STAT.(make_tlc("x = foo #~ bar"))
    assert_equal "x = foo ", stat.code
  end

  def test_returns_nil_on_empty_input
    assert_nil EAT_STAT.(make_tlc(""))
  end

  def test_bare_instr_name_and_args
    stat = EAT_STAT.(make_tlc("x = 1 #~ foo bar baz"))
    assert_equal "foo", stat.instr.name
    assert_equal ["bar", "baz"], stat.instr.args
  end

  def test_question_mark_instr
    stat = EAT_STAT.(make_tlc("x #~ foo?"))
    assert_equal :next_if_present, stat.instr.name
    assert_equal ["foo"], stat.instr.args
  end

  def test_exclamation_instr
    stat = EAT_STAT.(make_tlc("x #~ foo!"))
    assert_equal :rm_if_absent, stat.instr.name
    assert_equal ["foo"], stat.instr.args
  end

  def test_next_stat_on_second_line
    tlc = make_tlc("a #~ foo\nb #~ bar")
    stat = EAT_STAT.(tlc)
    assert_equal "foo", stat.instr.name
    assert_equal "bar", stat.next_stat.instr.name
  end

  def test_no_magic_comment_gives_nil_instr
    stat = EAT_STAT.(make_tlc("x = 1"))
    assert_nil stat.instr
  end
end
