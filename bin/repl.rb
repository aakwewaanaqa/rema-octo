require_relative '../src/src'

include Oppl::Tokenize
include Oppl::Ast
include Oppl::Ast::Instr
include Oppl::Iterate

HISTORY_FILE = File.join(Dir.pwd, '.repl.history')

def run_node(node, val = nil, ctx = Shared::Context.new)
  result = dispatch(node, val, ctx)
  unless result[:ok]
    puts "Unknown: #{node.name}"
    return
  end
  if node.pipe_instr
    run_node(node.pipe_instr, result[:result], ctx)
  elsif node.next_instr
    p result[:result]
    run_node(node.next_instr, nil, ctx)
  else
    p result[:result]
  end
end

def run_line(line)
  tc = TokenConsumer.new(TOKENIZE.(StringConsumer.new(line)))
  parse_result = EAT_INSTR.(false, AstFlowResult.new(tc, {}))
  if parse_result.ok?
    run_node(parse_result[:instr], nil, Shared::Context.new)
  else
    puts parse_result[:error]&.dig(:message) || "parse error"
  end
end

# -e "command" 模式
if (idx = ARGV.index('-e'))
  run_line(ARGV[idx + 1])
  exit
end

# pipe / stdin 模式
unless $stdin.tty?
  buffer = ''
  $stdin.each_line do |line|
    stripped = line.chomp
    if stripped.strip.start_with?('|>') && !buffer.empty?
      buffer += ' ' + stripped.strip
    else
      run_line(buffer) unless buffer.empty?
      buffer = stripped
    end
  end
  run_line(buffer) unless buffer.empty?
  exit
end

require 'readline'

if File.exist?(HISTORY_FILE)
  File.readlines(HISTORY_FILE, chomp: true).each { |l| Readline::HISTORY << l }
end

while (line = Readline.readline('> ', true))
  next if line.strip.empty?
  File.open(HISTORY_FILE, 'a') { |f| f.puts line }
  run_line(line)
end
