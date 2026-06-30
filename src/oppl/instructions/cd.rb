module Oppl
  module Instructions
    class Cd
      def self.lsp_tokens(node)
        tokens = [{ pos: node.start_pos, length: node.name.length, type: :keyword }]
        node.args.each do |arg|
          next unless arg.last == :identifier
          tokens << { pos: arg.readable_pos, length: arg.text.length, type: :string }
        end
        tokens
      end

      def self.check args, mods, val, ctx, &block
        return 'missing args[0]' if args.nil? || args.empty?
        nil
      end

      def self.call args, mods, val, ctx, &block
        path = File.expand_path(args[0])
        Dir.chdir path
        Dir.pwd
      end
    end
  end
end
