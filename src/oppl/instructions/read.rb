module Oppl
  module Instructions
    # reads a file as string by abs __FILE__ appending relative_path
    class Read
      def self.lsp_tokens(node)
        tokens = [{ pos: node.start_pos, length: node.name.length, type: :keyword }]
        node.args.each do |arg|
          next unless arg.last == :identifier
          tokens << { pos: arg.readable_pos, length: arg.text.length, type: :string }
        end
        tokens
      end

      def self.check args, mods, val, ctx, &block
      end

      def self.call args, mods, val, ctx, &block
        relative_path = args&.[](0) || val
        oppl_path = ctx&.[](:__DIR__) || '.'
        abs_path = File.join oppl_path, relative_path
        File.read abs_path
      end
    end
  end
end
