require 'json'
require_relative '../src/src'

include Oppl::Tokenize
include Oppl::Ast
include Oppl::Ast::Instr
include Oppl::Iterate

def fail!(code, message, fix)
  puts JSON.generate({
    ok: false,
    error: { code: code, message: message },
    fix: fix
  })
  exit(1)
end

oppl_file = ARGV[0]

fail!("MISSING_ARG", "No .oppl file provided", "Usage: ruby bin/main.rb <file.oppl>") if oppl_file.nil?
fail!("FILE_NOT_FOUND", "File '#{oppl_file}' does not exist", "Check that the file path is correct") unless File.exist?(oppl_file)

file_content = File.read(oppl_file)
tc = TokenConsumer.new(TOKENIZE.(StringConsumer.new(file_content)))
parse_result = EAT_INSTR.(false, AstFlowResult.new(tc, {}))

unless parse_result.ok?
  err = parse_result[:error]
  fail!("PARSE_ERROR", err[:message], "Fix the syntax error in your .oppl file at #{err[:readable_pos]}")
end

result = iterate(parse_result[:instr])

puts JSON.generate({ ok: true, result: result })
