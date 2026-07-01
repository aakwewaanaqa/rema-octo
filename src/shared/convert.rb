module Shared
  module Convert
    ConvResult = Struct.new(:val, :ok)

    NOT_OK = ConvResult.new(nil, false)

    # tries to turn s into Regexp
    # if fails it will be a string
    TRY_AS_REGEXP = -> s {
      return nil unless s
      s =~ /\A\/(.*)\/(.*)\z/ ? 
        ConvResult.new(Regexp.new($1, $2), true) : 
        ConvResult.new(s, false)
    }

    TO_FLAT_STRING = -> obj {
      case obj
      when String then obj
      when Array  then obj.flatten.join("\n")
      else             obj.to_s
      end
    }
  end
end