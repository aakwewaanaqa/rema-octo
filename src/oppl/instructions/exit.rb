module Oppl
  module Instructions
    class Exit
      def self.check args, mods, val, ctx, &block
        nil
      end

      def self.call args, mods, val, ctx, &block
        exit 0
      end
    end
  end
end
