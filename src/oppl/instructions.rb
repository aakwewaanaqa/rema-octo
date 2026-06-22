module Oppl
  module Instructions
    def self.to_pattern(s)
      s =~ /\A\/(.*)\/(.*)\z/ ? Regexp.new($1) : s
    end
  end
end
