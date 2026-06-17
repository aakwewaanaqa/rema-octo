module Tokenize
  TOKENIZE = -> sc {
    tokens = []
    while sc.done? == false
      if token = Shared::DO_SPACES.(sc) || 
                 Shared::DO_NEW_LINE.(sc) || 
                 Shared::DO_LITERAL.(sc) || 
                 Shared::DO_PIPE.(sc) || 
                 Shared::DO_IDENTIFIER.(sc) || 
                 Shared::DO_COLON.(sc) || 
                 Shared::DO_OPEN_BRACE.(sc) || 
                 Shared::DO_CLOSE_BRACE.(sc) || 
                 Shared::DO_COMMENT.(sc)
        tokens << token
      else
        peak = sc.advance
        tokens << Shared::Token.new(:unknown, peak, sc.readable_pos)
      end
    end

    return tokens
  }
end

def split_the_text_by_delimiter text, del 
  sc = Shared::StringConsumer.new text
  tokens = []
  buf = ''
  
  while peak = sc.advance
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
