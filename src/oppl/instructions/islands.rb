module Oppl
  module Instructions
    # which sparate string by empty line to array
    # example:
    #   1. this picks up all texts
    #     read <file> |> islands
    #   2. this picks up comments
    #     read <file> |> islands:start_with '//'
    module Islands
      def self.check args, mods, val, ctx, &block
        
      end
      def self.call args, mods, val, ctx, &block
        return [] if !val || val.empty?

        lc = Shared::LineConsumer.new val
        start_with = mods&.dig(:start_with)&.then { |v| Instructions.to_pattern(v.first) if v.first }
        sub = mods&.dig(:-)&.then { |v| Instructions.to_pattern(v.first) if v.first }

        islands = []
        cache = ''

        while peak = lc.advance
          encounter_straits =
            peak.empty? ||
            (start_with && !peak.start_with?(start_with))
          if encounter_straits
            islands << cache unless cache.empty?
            cache = ''
          else
            peak = peak.sub(sub, '') if sub
            cache << peak << "\n"
            # why we dont need to check start_with to append
            # 'cause those did not starts with start_with are straits
            # and when encountered the cache is empty so it wont append
            # so magical...
          end
        end
        islands << cache unless cache.empty?
        islands
      end
    end
  end
end