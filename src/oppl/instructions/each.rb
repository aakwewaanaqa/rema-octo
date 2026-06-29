module Oppl
  module Instructions
    class Each
      def self.check args, mods, val, ctx, &block
      end

      def self.call args, mods, val, ctx, &block
        return [] unless block
        Array(val).map { |item|
          result = block.(item)
          result.is_a?(Hash) && result.key?(:result) ? result[:result] : result
        }
      end
    end
  end
end
