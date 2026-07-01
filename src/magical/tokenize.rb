module Magical
  module Tokenize
    # compat stands for comment_start_pattern
    TOKENIZE = -> (txt, compat = /#~|\/{2}~/) {
      tokenize = -> sc {
        tokens = []
        while sc.done? == false
          if token = 
              Shared::DO_SPACES.(sc) || 
              Shared::DO_SEMI_COLON.(sc) || 
              Shared::DO_QUESTION_MARK.(sc) || 
              Shared::DO_EXCLAMATION.(sc) || 
              Shared::DO_IDENTIFIER.(sc) || 
              Shared::DO_LITERAL.(sc) || 
              Shared::DO_COMMENT.(sc)
            tokens << token
          else
            pos = sc.readable_pos
            peak = sc.advance
            tokens << Shared::Token.new(:unknown, peak, pos)
          end
        end
    
        return tokens
      }.curry

      lc = Shared::LineConsumer.new txt
      tokens = []
      while peak = lc.advance
        code, comment = peak.split compat
        code_token = Shared::Token.new(:code, code, lc.readable_pos)
        tokens << code_token
        if comment && !comment.empty?
          sc = Shared::StringConsumer.new comment
          sc.readable_pos_offset = lc.readable_pos
          tokens.concat tokenize.(sc)
        end
        tokens << Shared::Token.new(:new_line, "\n", lc.readable_pos)
      end

      tokens
    }
  end
end