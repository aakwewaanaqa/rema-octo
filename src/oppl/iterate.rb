module Oppl
  module Iterate
    def resolve_val(v, vars)
      ::Shared::LiteralResolver.new(v).resolve(vars)
    end

    def dispatch(node, pipe_val, ctx = ::Shared::Context.new)
      klass = Instructions.const_get(node.name.capitalize)
      args = node.args.map { |v| resolve_val(v.text, ctx.vars) }
      mods = node.mods.transform_values { |vals| vals.map { |v| resolve_val(v.text, ctx.vars) } }
      block_fn = node.block_instr ? -> (child_ctx, v = nil) { iterate(node.block_instr, v, child_ctx) } : nil
      wrapped = block_fn ? proc { |v = nil| block_fn.(ctx.child, v) } : nil
      { ok: true, result: klass.(args, mods, pipe_val, ctx, &wrapped) }
    rescue => e
      puts e.full_message
      return { ok: false, error: { message: e, file: "#{ctx&.[](:__FILE__)}:#{node.start_pos.line}" }}
    end

    def iterate(node, pipe_val = nil, ctx = ::Shared::Context.new)
      result = dispatch(node, pipe_val, ctx)
      return result unless result[:ok]
      result = iterate(node.pipe_instr, result[:result], ctx) if node.pipe_instr
      return iterate(node.next_instr, nil, ctx) if node.next_instr
      result
    end
  end
end
