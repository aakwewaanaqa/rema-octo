require_relative '../src/oppl/shared/string_consumer.rb'
require_relative '../src/oppl/tokenize.rb'
require_relative '../src/oppl/parse.rb'
require_relative '../src/oppl/processor.rb'
include Processor
include Parse

oppl_cmd  = ARGV[0]
oppl_file = ARGV[1]

if oppl_cmd.nil? || oppl_file.nil?
  puts "Usage: ruby main.rb <oppl_cmd> <oppl_file>"
  exit(1)
end

if !File.exist?(oppl_file)
  puts "Error: File '#{oppl_file}' does not exist."
  exit(1)
end

file_content = File.read(oppl_file)
consumer = StringConsumer.new file_content

require 'pp'
if oppl_cmd == 'tokenize'
  include Tokenize
  pp(Tokenize.tokenize(consumer))
  exit 0
end