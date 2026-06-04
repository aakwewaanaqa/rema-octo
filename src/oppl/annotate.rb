Line = Struct.new(:indent, :pipe, :text, :line_num)

def _count_indention line
  indention = 0
  consumer = StringConsumer.new line
  while peak = consumer.advance!
    if peak == ' '
      indention += 1
    elsif peak == "\t"
      indention += 1
    else
      break
    end
  end

  return indention
end

def annotate_the_line line, line_num
  indent = _count_indention line
  pipe = line[indent, 2] == '|>'
  indent_of_pipe_or_not = indent + (pipe ? 2 : 0)
  text = line[indent_of_pipe_or_not, line.length - indent_of_pipe_or_not]
  return Line.new(indent, pipe, text, line_num)
end