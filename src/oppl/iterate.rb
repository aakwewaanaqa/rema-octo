module Iterate
  def dispatch(node, pipe_val)
    fn = Instructions::REGISTRY[node.name]
    return { ok: false, error: { code: "UNKNOWN_INSTRUCTION", message: "Unknown instruction: #{node.name}" }, fix: "Check the instruction name" } if fn.nil?
    block_fn = node.block_instr ? -> { iterate(node.block_instr) } : nil
    fn.(node.args, node.mods, block_fn, pipe_val)
  end

  def iterate(node, pipe_val = nil)
    result = dispatch(node, pipe_val)
    return result unless result[:ok]
    result = iterate(node.pipe_instr, result[:result]) if node.pipe_instr
    return iterate(node.next_instr) if node.next_instr
    result
  end
end
