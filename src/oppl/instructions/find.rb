module Oppl
  module Instructions
    class Find
      def self.check args, mods, val, ctx, &block
      end

      def self.call args, mods, val, ctx, &block
        results = []
        pattern = Regexp.new args[0]
        Dir.each_child('.') { |child|
          results << child if pattern.match? child
        }
        results
      end
    end
  end
end
