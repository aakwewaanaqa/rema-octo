module Oppl
  module Instructions
    class N
      def self.check args, mods, val, ctx, &block 
        
      end
      def self.call args, mods, val, ctx, &block 
        raise '' unless args && args.length > 0
        raise '' unless val
        raise '' unless val.is_a?(Array)
        
        index = args&.[](0).to_i
        val&.[](index)
      end
    end
  end
end