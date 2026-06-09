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

  def do_new_line consumer 
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    text = ''
    peak = consumer.sneak_peek
    while peak == "\n" || peak == "\r"
      text += consumer.advance!
      peak = consumer.sneak_peek
    end

    return nil if text.empty?
    return Token.new(:new_line, text, pos)
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
    while /[a-zA-Z0-9_.]/.match(peak)
      text += consumer.advance!
      peak = consumer.sneak_peek
      break if peak.nil?
    end

    return nil if text.empty?
    return Token.new(:identifier, text, pos)
  end

  def do_literal consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    text = ''
    peak = consumer.sneak_peek
    if peak == "'" || peak == '"' || peak == '`'
      text += consumer.advance!
      while consumer.literaling
        text += consumer.advance!
        break if consumer.done?
      end
    end

    return nil if text.empty?
    return Token.new(:literal, text, pos)
  end

  def do_colon consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    if consumer.str_advance ':'
      return Token.new(:colon, ':', pos)
    end

    return nil
  end

  def do_open_brace consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    if consumer.str_advance '{'
      return Token.new(:open_brace, '{', pos)
    end

    return nil
  end

  def do_close_brace consumer
    return nil if consumer.literaling || consumer.done?
    
    pos = consumer.readable_pos
    if consumer.str_advance '}'
      return Token.new(:close_brace, '}', pos)
    end

    return nil
  end

  def do_comment consumer
      return nil if consumer.literaling || consumer.done?
      
      pos = consumer.readable_pos
      text = ''
      if consumer.str_advance '#'
        text += '#'
        peak = consumer.sneak_peek
        while peak != "\n" && peak != "\r" && !consumer.done?
          text += consumer.advance!
          peak = consumer.sneak_peek
        end
      end
  
      return nil if text.empty?
      return Token.new(:comment, text, pos)
  end

  def tokenize consumer
    tokens = []
    while consumer.done? == false
      if token = do_spaces(consumer) || 
                 do_new_line(consumer) || 
                 do_literal(consumer) || 
                 do_pipe(consumer) || 
                 do_identifier(consumer) || 
                 do_colon(consumer) || 
                 do_open_brace(consumer) || 
                 do_close_brace(consumer) || 
                 do_comment(consumer)
        tokens << token
      else
        peak = consumer.advance!
        tokens << Token.new(:unknown, peak, consumer.readable_pos)
      end
    end

    return tokens
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
