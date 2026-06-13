module Tokenize
  Token = Struct.new(:last, :text, :readable_pos)

  DO_SPACES = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    peak = sc.sneak_peek
    while peak == ' ' || peak == "\t"
      text += sc.advance!
      peak = sc.sneak_peek
    end

    return nil if text.empty?
    return Token.new(:spaces, text, pos)
  }

  DO_NEW_LINE = -> sc { 
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    peak = sc.sneak_peek
    while peak == "\n" || peak == "\r"
      text += sc.advance!
      peak = sc.sneak_peek
    end

    return nil if text.empty?
    return Token.new(:new_line, text, pos)
  }

  DO_PIPE = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance '|>'
      return Token.new(:pipe, '|>', pos)
    end

    return nil
  }

  DO_IDENTIFIER = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    peak = sc.sneak_peek
    while /[a-zA-Z0-9_.]/.match(peak)
      text += sc.advance!
      peak = sc.sneak_peek
      break if peak.nil?
    end

    return nil if text.empty?
    return Token.new(:identifier, text, pos)
  }

  DO_LITERAL = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    peak = sc.sneak_peek
    if peak == "'" || peak == '"' || peak == '`'
      text += sc.advance!
      while sc.literaling
        text += sc.advance!
        break if sc.done?
      end
    end

    return nil if text.empty?
    return Token.new(:literal, text, pos)
  }

  DO_COLON = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance ':'
      return Token.new(:colon, ':', pos)
    end

    return nil
  }

  DO_OPEN_BRACE = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance '{'
      return Token.new(:open_brace, '{', pos)
    end

    return nil
  }

  DO_CLOSE_BRACE = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance '}'
      return Token.new(:close_brace, '}', pos)
    end

    return nil
  }

  DO_COMMENT = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    if sc.str_advance '#'
      text += '#'
      peak = sc.sneak_peek
      while peak != "\n" && peak != "\r" && !sc.done?
        text += sc.advance!
        peak = sc.sneak_peek
      end
    end

    return nil if text.empty?
    return Token.new(:comment, text, pos)
  }

  TOKENIZE = -> sc {
    tokens = []
    while sc.done? == false
      if token = DO_SPACES.(sc) || 
                 DO_NEW_LINE.(sc) || 
                 DO_LITERAL.(sc) || 
                 DO_PIPE.(sc) || 
                 DO_IDENTIFIER.(sc) || 
                 DO_COLON.(sc) || 
                 DO_OPEN_BRACE.(sc) || 
                 DO_CLOSE_BRACE.(sc) || 
                 DO_COMMENT.(sc)
        tokens << token
      else
        peak = sc.advance!
        tokens << Token.new(:unknown, peak, sc.readable_pos)
      end
    end

    return tokens
  }
end

def split_the_text_by_delimiter text, del 
  sc = StringConsumer.new text
  tokens = []
  buf = ''
  
  while peak = sc.advance!
    buf += peak

    if buf[-del.length, del.length] == del && !sc.literaling
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
    |token| token.strip
  end
end

def split_the_text_by_space text
  return split_the_text_by_delimiter text, ' '
end
