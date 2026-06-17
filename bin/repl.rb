require_relative '../src/oppl'

include Tokenize
include Ast
include Ast::Instr

HISTORY_FILE = './.repl.history'

def resolve_val(v, ctx)
  return v unless v.is_a?(String) && v.length >= 2 && v[0] == v[-1] && %w[" '].include?(v[0])
  Shared::LiteralResolver.new(v).resolve(ctx.vars)
end

def dispatch(node, val = nil, ctx = Shared::Context.new)
  klass = Instructions.const_get(node.name.capitalize)
  r_args = node.args&.map { |a| resolve_val(a, ctx) } || []
  r_mods = node.mods&.transform_values { |v| resolve_val(v, ctx) } || {}
  r_val  = resolve_val(val, ctx)
  block_fn = node.block_instr ? -> (child_ctx, v = nil) { dispatch(node.block_instr, v, child_ctx) } : nil
  wrapped = block_fn ? proc { |v = nil| block_fn.(ctx.child, v) } : nil
  klass.(r_args, r_mods, r_val, ctx, &wrapped)
rescue NameError
  puts "Unknown: #{node.name}"
end

def run_node(node, val = nil, ctx = Shared::Context.new)
  result = dispatch(node, val, ctx)
  if node.pipe_instr
    run_node(node.pipe_instr, result, ctx)
  elsif node.next_instr
    p result
    run_node(node.next_instr, nil, ctx)
  else
    p result
  end
end

require 'readline'

if File.exist?(HISTORY_FILE)
  File.readlines(HISTORY_FILE, chomp: true).each { |l| Readline::HISTORY << l }
end

while (line = Readline.readline('> ', true))
  next if line.strip.empty?
  File.open(HISTORY_FILE, 'a') { |f| f.puts line }
  tc = TokenConsumer.new(TOKENIZE.(StringConsumer.new(line)))
  parse_result = EAT_INSTR.(false, AstFlowResult.new(tc, {}))
  if parse_result.ok?
    run_node(parse_result[:instr], nil, Shared::Context.new)
  else
    puts parse_result[:error]&.dig(:message) || "parse error"
  end
end
