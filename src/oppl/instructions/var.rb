module Oppl
  module Instructions
    # if args[0] exists and val is provided meaning we want to set a variable
    # if args[0] exists but val is not provided meaning we want to read a variable
    class Var
      USAGE = "
# if args[0] exists and val is provided meaning we want to set a variable
# if args[0] exists but val is not provided meaning we want to read a variable
      "

      def self.lsp_tokens(node)
        tokens = [{ pos: node.start_pos, length: node.name.length, type: :keyword }]
        arg0 = node.args[0]
        if arg0
          tokens << { pos: arg0.readable_pos, length: arg0.text.length, type: :variable }
        end
        tokens
      end

      def self.check args, mods, val, ctx, &block
        return USAGE unless args&.[](0)
        nil
      end

      def self.auto_val(v)
        return v unless v.is_a?(String) && v.include?(',')
        v.split(',').map(&:strip)
      end

      def self.call args, mods, val, ctx, &block
        arg0 = args&.[](0)&.to_sym
        if val
          ctx.vars[arg0] = auto_val(val)
          return ctx.vars[arg0]
        else
          return ctx.vars[arg0]
        end
      end
    end
  end
end