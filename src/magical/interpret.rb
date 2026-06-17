module Magical
  module Interpret
    def interpret_line(line_str, magic_comment = /#~|\/{2}~/, vars = {})
      txt, cast = line_str.split magic_comment
      
    end
  end
end