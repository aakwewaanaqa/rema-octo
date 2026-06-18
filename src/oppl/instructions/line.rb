module Oppl
  module Instructions
    class Line
      def self.check
      end

      def self.call args, mods, val, ctx, &block
        lines = val.split "\n"
        lines[args[0].to_i]
      end
    end
  end
end
