module Shared
  Token = Struct.new(:last, :text, :readable_pos)

  DO_SPACES = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    peak = sc.sneak_peek
    while peak == ' ' || peak == "\t"
      text += sc.advance
      peak = sc.sneak_peek
    end

    return nil if text.empty?
    return Token.new(:spaces, text, pos)
  }

  DO_NEW_LINE = -> sc { 
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if match = sc.match_advance(/\R+/)
      return Token.new(:new_line, match.to_s, pos)
    end

    nil
  }

  DO_PIPE = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance '|>'
      return Token.new(:pipe, '|>', pos)
    end

    nil
  }

  DO_SEMI_COLON = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance ';'
      return Token.new(:semi_colon, ';', pos)
    end

    return nil
  }

  DO_EXCLAMATION = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance '!'
      return Token.new(:exclamation, '!', pos)
    end

    return nil
  }

  DO_QUESTION_MARK = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    if sc.str_advance '?'
      return Token.new(:question_mark, '?', pos)
    end

    return nil
  }

  DO_IDENTIFIER = -> sc {
    return nil if sc.literaling || sc.done?
    
    pos = sc.readable_pos
    text = ''
    peak = sc.sneak_peek
    while /[a-zA-Z0-9_\-.~\/]/.match(peak)
      text += sc.advance
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
      text += sc.advance
      while sc.literaling
        text += sc.advance
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
    if peak = sc.str_advance('#')
      text += '#'
      peak = sc.sneak_peek
      while peak != "\n" && peak != "\r" && !sc.done?
        text += sc.advance
        peak = sc.sneak_peek
      end
    end

    return nil if text.empty?
    return Token.new(:comment, text, pos)
  }
end