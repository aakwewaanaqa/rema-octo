module Oppl
  module Instructions
    class Ls
      def self.check args, mods, val, ctx, &block
        nil
      end

      def self.call args, mods, val, ctx, &block
        results = []
        Dir.each_child('.') { |item|
          results << item
        }
        results
      end
    end
  end
end
