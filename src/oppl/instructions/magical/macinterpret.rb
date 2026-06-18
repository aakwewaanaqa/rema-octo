module Oppl
  module Instructions
    module Magical
      # Stands for magical interpret
      class Macinterpret
        def self.check args, mods, val, ctx, &block
          
        end
        def self.call args, mods, val, ctx, &block
          tokens = ::Magical::Tokenize::TOKENIZE.(val)
          tlc = ::Shared::TokenizedLineConsumer.new tokens
          stat = ::Magical::Ast::Stat::EAT_STAT.(tlc)
          ::Magical::Iterate::iterate stat, ctx
        end
      end
    end
  end
end