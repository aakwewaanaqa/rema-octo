module Oppl
  module Instructions
    # if args[0] exists and val is provided meaning we want to set a variable
    # if args[0] exists but val is not provided meaning we want to read a variable
    # if args[0] is missing but val is provided meaning we want to parse the .env like to set variables
    class Var
      USAGE = "
# if args[0] exists and val is provided meaning we want to set a variable
# if args[0] exists but val is not provided meaning we want to read a variable
# if args[0] is missing but val is provided meaning we want to parse the .env like to set variables      
      "

      def self.check args, mods, val, ctx, &block
        has_arg0 = args&.[](0) ? true : false
        has_val = val ? true : false
        return USAGE if !has_arg0 && !has_val
        nil
      end

      def self.auto_val(v)
        return v unless v.is_a?(String) && v.include?(',')
        v.split(',').map(&:strip)
      end

      def self.call args, mods, val, ctx, &block
        arg0 = args&.[](0)&.to_sym
        has_arg0 = arg0 ? true : false
        has_val = val ? true : false
        mod =
          has_arg0 && has_val ? :set_var :
          has_arg0 ? :read_var :
          has_val ? :set_vars :
          :fail

        case mod
        when :set_var
          ctx.vars[arg0] = auto_val(val)
          return ctx.vars[arg0]
        when :read_var
          return ctx.vars[arg0]
        when :set_vars
          Array(val).flat_map { |s| s.split(/\R/) }.each { |line|
            line.strip!
            next if line.empty?
            next if line.start_with?('#') && !line.start_with?('#!')
            directive = line.start_with?('#!') ? line[2..].strip : line
            key, _val = directive.split('=', 2)
            ctx.vars[key.strip.to_sym] = auto_val(_val&.strip)
          }
          return ctx.vars
        end
      end
    end
  end
end