module Oppl
  module Instructions
    class Scope
      def self.check args, mods, val, ctx, &block
        
      end

      def self.call args, mods, val, ctx, &block
        sc = Shared::StringConsumer.new val
        open = Instructions.to_pattern(args[0])
        is_open_pattern = open.is_a?(Regexp)
        close = Instructions.to_pattern(args[1])
        is_close_pattern = close.is_a?(Regexp)
        result = ''

        until sc.done?
          break if is_open_pattern ? sc.match_advance(open) : sc.str_advance(open)
          sc.advance
        end

        until sc.done?
          break if is_close_pattern ? sc.match_advance(close) : sc.str_advance(close)
          result += sc.advance
        end

        result
      end
    end
  end
end