# frozen_string_literal: true

require "minitest/autorun"
require_relative "../src/src"

class TestMagicalIterate < Minitest::Test
  TEMPLATE = File.read(File.join(__dir__, "../docs/usage/examples/example_2.cs"))

  def make_ctx(**vars)
    ctx = Shared::Context.new
    vars.each { |k, v| ctx[k] = v }
    ctx
  end

  def run_macinterpret(ctx)
    Oppl::Instructions::Magical::Macinterpret.call([], [], TEMPLATE, ctx)
  end

  ALL_VARS = {
    name_controller: "UserController",
    type_return: "UserDto",
    str_endpoint: "GetUser",
    type_dto: "UserRequestDto",
    str_method: "GET",
  }

  def test_substitutes_all_vars
    result = run_macinterpret(make_ctx(**ALL_VARS))
    assert_includes result, "UserController"
    assert_includes result, "UserDto"
    assert_includes result, "GetUser"
    assert_includes result, "UserRequestDto"
    assert_includes result, "GET"
  end

  def test_rm_if_absent_removes_dto_line
    result = run_macinterpret(make_ctx(**ALL_VARS.reject { |k| k == :type_dto }))
    refute_includes result, "type_dto dto,"
  end

  def test_rm_if_absent_keeps_dto_line_when_present
    result = run_macinterpret(make_ctx(**ALL_VARS))
    assert_includes result, "UserRequestDto dto,"
  end
end
