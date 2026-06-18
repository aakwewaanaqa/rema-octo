module Oppl
  module Instructions
    class Var
      def self.check args, mods, val, ctx, &block
        
      end
      def self.call args, mods, val, ctx, &block
        name = args[0].to_sym
        ctx.vars[name] = val
        val
      end
    end
  end
end