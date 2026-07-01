module Magical
  module Instructions
    class Rp
      def self.check code, args, ctx
        return 'args.length must > 0' if args.nil? || args.empty?
        nil
      end
      def self.call code, args, ctx
        args.each { |name|
          code = code.sub(name, ctx.vars[name.to_sym] || '')
        }
        code
      end
    end
  end
end