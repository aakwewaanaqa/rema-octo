module Tokenize
  Token = Struct.new(:type, :text, :readable_pos)

  def do_spaces consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    text = ''
    peak = consumer.sneak_peek
    while peak == ' ' || peak == "\t"
      text += consumer.advance!
      peak = consumer.sneak_peek
    end

    return nil if text.empty?
    return Token.new(:spaces, text, pos)
  end

  def do_pipe consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    if consumer.str_advance '|>'
      return Token.new(:pipe, '|>', pos)
    end

    return nil
  end

  def do_identifier consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    text = ''
    peak = consumer.sneak_peek
    while /[a-zA-Z0-9_]/.match(peak)
      text += consumer.advance!
      peak = consumer.sneak_peek
    end

    return nil if text.empty?
    return Token.new(:identifier, text, pos)
  end

  def tokenize consumer
    candidates = [
      /[ \t]+/,
      /[|][>]/,
      /[a-zA-Z0-9_]+/,
      /:/,
      /[\n\r]+/,
    ]
    while peak = consumer.match_advance
      
    end
  end
end

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
