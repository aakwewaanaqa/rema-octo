module Oppl
  module Instructions
    class Write
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
        path = args[0]
        mode = (mods[:mode] || :replace).to_sym
        _to_s = Shared::Convert::TO_FLAT_STRING.(val)
        case mode
        when :replace
          IO.write path, _to_s
        when :append
          offset = File.size path
          IO.write path, _to_s, offset
        end

        _to_s
      end
    end
  end
end
