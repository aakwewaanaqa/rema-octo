module Oppl
  module Instructions
    module Magical
      # Stands for magical interpret
      class Macinterpret
        def self.check args, mods, val, ctx, &block
          
        end
        def self.call args, mods, val, ctx, &block
          compat = ::Shared::Convert::TRY_AS_REGEXP.(mods&.[](:compat)&.[](0))&.val || /#~|\/{2}~/
          tokens = ::Magical::Tokenize::TOKENIZE.(val, compat)
          tlc = ::Shared::TokenizedLineConsumer.new tokens
          stat = ::Magical::Ast::Stat::EAT_STAT.(tlc)
          ::Magical::Iterate::iterate stat, ctx
        end
      end
    end
  end
end