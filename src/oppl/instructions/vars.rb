module Oppl
  module Instructions
    # parses .env-like content from val and sets multiple variables at once
    class Vars
      USAGE = "
# vars parses .env-like content from val and sets multiple variables at once
# requires val (piped or direct), no positional args needed
# lines starting with # are skipped; #! prefix marks directives
      "

      def self.lsp_tokens(node)
        [{ pos: node.start_pos, length: node.name.length, type: :keyword }]
      end

      def self.check args, mods, val, ctx, &block
        return USAGE unless val
        nil
      end

      def self.auto_val(v)
        return v unless v.is_a?(String) && v.include?(',')
        v.split(',').map(&:strip)
      end

      def self.call args, mods, val, ctx, &block
        Array(val).flat_map { |s| s.split(/\R/) }.each { |line|
          line.strip!
          next if line.empty?
          next if line.start_with?('#') && !line.start_with?('#!')
          directive = line.start_with?('#!') ? line[2..].strip : line
          key, _val = directive.split('=', 2)
          ctx.vars[key.strip.to_sym] = auto_val(_val&.strip)
        }
        ctx.vars
      end
    end
  end
end
