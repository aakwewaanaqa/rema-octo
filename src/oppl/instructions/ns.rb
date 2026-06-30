module Oppl
  module Instructions
    class Ns
      def self.lsp_tokens node
        tokens = [{
          pos: node.start_pos,
          length: node.name.length,
          type: :function
        }]

        node.args.each { |arg|
          tokens << {
            pos: arg.readable_pos,
            length: arg.text.length,
            type: :string
          }
        }

        tokens
      end

      def self.check args, mods, val, ctx, &block
      end

      def self.call args, mods, val, ctx, &block
        raise '' unless val
        raise '' unless val.is_a?(Array)

        return val if args.nil? || args.empty?

        range_str = args[0].to_s.strip
        range = eval(range_str)

        raise '' unless range.is_a?(Range)

        val[range]
      end
    end
  end
end