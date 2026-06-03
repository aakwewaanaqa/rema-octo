def split_the_text_by_delimiter text, del 
  consumer = StringConsumer.new text
  tokens = []
  buf = ''
  
  while peak = consumer.advance!
    buf += peak

    if buf[-del.length, del.length] == del && !consumer.literaling
      tokens << buf[0, buf.length - del.length] unless buf.empty?
      buf = ''
    end

  end

  tokens << buf unless buf.empty?
  return tokens
end

def split_the_text_by_pipe text
  tokens = split_the_text_by_delimiter text, '|>'
  return tokens.map {
    |token| token.strip
  }
end

def split_the_text_by_space text
  return split_the_text_by_delimiter text, ' '
end
