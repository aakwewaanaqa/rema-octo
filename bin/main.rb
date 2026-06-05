require_relative '../src/oppl/shared/string_consumer.rb'
require_relative '../src/oppl/tokenize.rb'
require_relative '../src/oppl/parse.rb'
require_relative '../src/oppl/processor.rb'
include Processor
include Parse

oppl_file = ARGV[0]

if oppl_file.nil?
  puts "Usage: ruby main.rb <oppl_file>"
  exit(1)
end

file_text = Processor.chomp_comment(File.read(oppl_file))
token = Parse.parse_instr_token StringConsumer.new(file_text), {}

require 'pp'
pp token