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
        var_name = node.args[0]
        if var_name
          tokens << { pos: var_name.readable_pos, length: var_name.text.length, type: :variable }
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
        if val
          array_splitter = mods&.[](:array)
          flat = mods&.key?(:flat)

          _DO_VAL = -> {
            val = ::Shared::Convert::TO_FLAT_STRING.(val) if flat
            val = val.split(array_splitter).map(&:strip) if array_splitter
          }

          _SET_VAR = -> {
            var_name = args[0]&.to_sym if args
            ctx[var_name] = val if ctx && var_name
          }

          _DO_VAL.()
          _SET_VAR.()
          return val
        else
          _GET_VAR = -> {
            var_name = args[0]&.to_sym if args
            return ctx[var_name] if ctx && var_name
            return nil
          }

          return _GET_VAR.()
        end
      end
    end
  end
end