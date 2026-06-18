module Magical
  module Instructions
    class NextIfPresent
      def self.call(code, args, ctx)
        return :stop unless args.all? { |var| ctx[var.to_sym] }
        code
      end
    end
  end
end
