module Oppl
  module Instructions
    class N
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
            type: :number
          }
        }

        tokens
      end

      def self.check args, mods, val, ctx, &block 
        
      end

      def self.call args, mods, val, ctx, &block 
        raise '' unless args && args.length > 0
        raise '' unless val
        raise '' unless val.is_a?(Array)
        
        index = args&.[](0).to_i
        val&.[](index)
      end
    end
  end
end