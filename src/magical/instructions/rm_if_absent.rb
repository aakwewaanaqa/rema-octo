module Magical
  module Instructions
    class RmIfAbsent
      def self.call(code, args, ctx)
        return nil unless args.all? { |var| ctx[var.to_sym] }
        code
      end
    end
  end
end
