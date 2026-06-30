module Oppl
  module Instructions
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
        targets = []

        args.each { |arg|
          targets << arg
        } unless args.nil? || args.empty?

        case val
          when String then targets << val
          when Array then targets.concat(val) unless val.empty?
        end

        targets.each { |target|
          next unless File.file? target
          file_content = File.read target
          block.(file_content) unless block.nil?
        }

        if targets.length == 1
          return File.read targets[0]
        end

        nil
      end
    end
  end
end
