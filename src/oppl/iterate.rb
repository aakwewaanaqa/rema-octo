module Iterate
  def dispatch(node, pipe_val, ctx = Shared::Context.new)
    klass = Instructions.const_get(node.name.capitalize)
    block_fn = node.block_instr ? -> (child_ctx, v = nil) { dispatch(node.block_instr, v, child_ctx) } : nil
    wrapped = block_fn ? proc { |v = nil| block_fn.(ctx.child, v) } : nil
    { ok: true, result: klass.(node.args, node.mods, pipe_val, ctx, &wrapped) }
  rescue NameError
    { ok: false, error: { code: "UNKNOWN_INSTRUCTION", message: "Unknown instruction: #{node.name}" } }
  end

  def iterate(node, pipe_val = nil, ctx = Shared::Context.new)
    result = dispatch(node, pipe_val, ctx)
    return result unless result[:ok]
    result = iterate(node.pipe_instr, result[:result], ctx) if node.pipe_instr
    return iterate(node.next_instr, nil, ctx) if node.next_instr
    result
  end
end
