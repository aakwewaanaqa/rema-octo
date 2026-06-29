module Oppl
  module Instructions
    class Scope
      def self.check args, mods, val, ctx, &block
        
      end

      def self.call args, mods, val, ctx, &block
        sc = Shared::StringConsumer.new val
        open_r = Shared::Convert::TRY_AS_REGEXP.(args[0])
        seek_open = -> { open_r.ok ? sc.match_advance(open_r.val) : sc.str_advance(open_r.val) }
        close_r = Shared::Convert::TRY_AS_REGEXP.(args[1])
        seek_close = -> { close_r.ok ? sc.match_advance(close_r.val) : sc.str_advance(close_r.val) }

        keep_head = mods.key?(:keep_head)
        keep_tail = mods.key?(:keep_tail)

        result = ''

        until sc.done?
          if peak = seek_open.call
            result += peak.to_s if keep_head
            break
          end
          sc.advance
        end

        until sc.done?
          if peak = seek_close.call
            result += peak.to_s if keep_tail
            break
          end
          result += sc.advance
        end

        result
      end
    end
  end
end