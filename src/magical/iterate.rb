module Magical
  module Iterate
    extend self
    
    def dispatch(instr, code, ctx)
      klass_name = instr.name.to_s.split('_').map(&:capitalize).join
      klass = Magical::Instructions.const_get(klass_name)
      result = klass.call(code, instr.args.map(&:text), ctx)
      return result if result == :stop || result.nil?
      return dispatch(instr.next_instr, result, ctx) if instr.next_instr
      result
    end

    def iterate(stat, ctx = Shared::Context.new)
      return "" if stat.nil?

      code = stat.code || ""

      if stat.instr
        result = dispatch(stat.instr, code, ctx)
        return "" if result == :stop
        return iterate(stat.next_stat, ctx) if result.nil?
        code = result
      end

      code.rstrip + "\n" + iterate(stat.next_stat, ctx)
    end
  end
end
