module Oppl
  module Instructions
    class Scope
      def self.check args, mods, val, ctx, &block
        
      end

      def self.call args, mods, val, ctx, &block
        sc = Shared::StringConsumer.new val
        open_r = Shared::Convert::TRY_AS_REGEXP.(args[0])
        seek_open = -> {
          if open_r.ok
            pattern = open_r.val
            return sc.match_advance pattern
          else
            str = open_r.val
            return sc.str_advance str
          end
        }

        close_r = Shared::Convert::TRY_AS_REGEXP.(args[1])
        seek_close = -> {
          if close_r.ok
            pattern = close_r.val
            return sc.match_advance pattern
          else
            str = close_r.val
            return sc.str_advance str
          end
        }

        result = ''

        keep_head = mods.key?(:keep_head)
        keep_tail = mods.key?(:keep_tail)

        until sc.done?
          if peak = seek_open.call
            result += peak.to_s if keep_head
            break # breaks the loop of finding open
          end
          sc.advance # if it is not the open; advances more
        end

        until sc.done?
          if peak = seek_close.call
            result += peak.to_s if keep_tail
            break # breaks the loop of finding close
          end
          result += sc.advance # if it is not the close; takes more characters
        end

        result
      end
    end
  end
end