module Oppl
  module Instructions
    # which sparate string by empty line to array
    module Islands
      def self.check args, mods, val, ctx, &block
        
      end
      def self.call args, mods, val, ctx, &block
        content = args&.[](0) || val
        lc = Shared::LineConsumer.new content
        islands = []
        cache = ''
        while peak = lc.advance
          if peak.empty?
            islands << cache unless cache.empty?
            cache = ''
          else
            cache << peak << "\n"
          end
        end
        islands << cache unless cache.empty?
        islands
      end
    end
  end
end