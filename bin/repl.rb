require_relative '../src/oppl'

include Tokenize
include Ast
include Ast::Instr

def dispatch(node, val = nil, ctx = Shared::Context.new)
  klass = Instructions.const_get(node.name.capitalize)
  block_fn = node.block_instr ? -> (child_ctx, v = nil) { dispatch(node.block_instr, v, child_ctx) } : nil
  wrapped = block_fn ? proc { |v = nil| block_fn.(ctx.child, v) } : nil
  klass.(node.args, node.mods, val, ctx, &wrapped)
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
while (line = Readline.readline('> ', true))
  next if line.strip.empty?
  tc = TokenConsumer.new(TOKENIZE.(StringConsumer.new(line)))
  parse_result = EAT_INSTR.(false, AstFlowResult.new(tc, {}))
  if parse_result.ok?
    run_node(parse_result[:instr], nil, Shared::Context.new)
  else
    puts parse_result[:error]&.dig(:message) || "parse error"
  end
end
