def split_the_text_by_delimiter text, del 
  consumer = StringConsumer.new text
  tokens = []
  buf = ''
  
  while peak = consumer.advance!
    buf += peak

    if buf[-del.length, del.length] == del && !consumer.literaling
      content = buf[0, buf.length - del.length]
      tokens << content unless content.empty?
      buf = ''
    end

  end

  tokens << buf unless buf.empty?
  return tokens
end

def split_the_text_by_pipe text
  tokens = split_the_text_by_delimiter text, '|>'
  return tokens.map do
    |token| return token.strip
  end
end

def split_the_text_by_space text
  return split_the_text_by_delimiter text, ' '
end
