module Oppl
  module Instructions
    class Regex
      def self.call args, mods, val, ctx, &block
        raise 'val has to be a String' unless val.is_a?(String)

        pattern_result = ::Shared::Convert::TRY_AS_REGEXP.(args[0])
        raise 'args[0] is not a pattern' unless pattern_result.ok
        
        pattern = pattern_result.val
        match = val.match pattern

        if out = match[1] then return out end
        if out = match[0] then return out end

        ''
      end
    end
  end
end