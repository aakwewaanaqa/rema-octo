module Ast
  class AstFlowResult
    attr_reader :tc, :data

    def initialize tc, data
      @tc = tc
      @data = data
    end

    def [] key
      @data[key]
    end

    def []= key, val
      @data[key] = val
    end

    def ok?
      return @data[:ok]
    end

    def error?
      return @data[:error]
    end

    def terminated?
      return @data[:terminated]
    end

    def next_if_ok fn
      return self if @data[:terminated]
      ok? ? fn.call(self) : self
    end

    def if_fail fn
      return self if @data[:terminated]
      ok? ? self : fn.call(self)
    end

    def terminate_if predicate, on_terminate = nil
      return self if @data[:terminated]
      @data[:terminated] = true if predicate.(self)
      if @data[:terminated] then on_terminate.(self) unless on_terminate.nil? end
      self
    end

    def next fn
      return self if @data[:terminated]
      fn.call(self)
    end

    def resume
      @data[:terminated] = false
      self
    end
  end

  EAT_LEADING_SPACE = -> flow {
    ok = false
    line_crossed = false
    while peak = flow.tc.sneak_peek
      case peak.type
        when :comment
          flow.tc.advance
          ok = true
          line_crossed = true
        when :spaces
          flow.tc.advance
          ok = true
        when :new_line
          flow.tc.advance
          ok = true
          line_crossed = true
        else
          break
      end
    end
    Ast::AstFlowResult.new(flow.tc, {
      :last => 'EAT_LEADING_SPACE',
      :line_crossed => line_crossed,
      :ok => ok 
    })
  }

  EAT_NAME = -> flow {
    peak = flow.tc.sneak_peek
    name = ''
    case peak.type
      when :literal
        name = peak.text
        flow.tc.advance
      when :identifier
        name = peak.text
        flow.tc.advance
    end

    AstFlowResult.new(flow.tc, {
      :last => 'EAT_NAME',
      :name => name,
      :ok => !name.empty?
    })
  }

  EAT_PIPE = -> flow {
    ok = false
    peak = flow.tc.sneak_peek
    if peak.type == :pipe
      token_consumer.advance
      ok = true
    end

    AstFlowResult.new(flow.tc, {
      :last => 'EAT_PIPE',
      :ok => ok
    })
  }

  EAT_INSTR = -> in_pipe, flow {
    instr_name = nil
    instr_args = []
    instr_mods = {}
    block_instr = nil
    pipe_instr = nil
    next_instr = nil

    _INSERT_TO_FLOW = -> flow {
      instr_args = instr_args.empty? ? nil : instr_args
      instr_mods = instr_mods.empty? ? nil : instr_mods
      flow[:instr] = {
        :instr_name => instr_name,
        :instr_args => instr_args,
        :instr_mods => instr_mods,
        :block_instr => block_instr,
        :pipe_instr => pipe_instr,
        :next_instr => next_instr,
      }
      return flow
    }

    _NAME_LOOP = -> array_to_push, flow {
      flow
        .next EAT_LEADING_SPACE
        .terminate_if -> flow { !flow.ok? }
        .terminate_if -> flow { flow[:line_crossed] }
        .next EAT_NAME
        .terminate_if -> flow { !flow.ok? }
        .next_if_ok -> flow { array_to_push << flow[:name]; flow }
        .next_if_ok _NAME_LOOP.(array_to_push) # Recursive Again
        .resume
    }.curry

    _ARG_LOOP = -> flow {
      flow
        .next EAT_LEADING_SPACE
        .terminate_if -> flow { flow[:line_crossed] }
        .next EAT_NAME
        .terminate_if -> flow { !flow.ok? }
        .next_if_ok -> flow { instr_name = flow[:name]; flow }
        .next _NAME_LOOP.(instr_args)
        .resume
    }

    _MOD_LOOP = -> flow {
      flow = flow.next EAT_LEADING_SPACE
      return flow if flow[:line_crossed]
      flow = flow.next EAT_NAME
      return flow if flow.ok? == false
      
      mod_key = flow[:name]
      mod_args = []
      flow = flow.next(_NAME_LOOP.(mod_args))
      instr_mods[mod_key] = mod_args
      return flow if flow[:line_crossed]

      flow = flow.next EAT_COLON
      return flow if flow.ok? == false
      return flow.next _MOD_LOOP
    }

    _ON_NEWLINE = -> flow {
      return flow if in_pipe
      flow = flow.next EAT_OPEN_BRACE
      if flow.ok?
        flow = flow.next(EAT_INSTR.(false))
        block_instr = flow[:instr]
      end

      flow = flow.next EAT_PIPE
      if flow.ok?
        flow = flow.next(EAT_INSTR.(true))
        pipe_instr = flow[:instr]
      end

      flow = flow.next(EAT_INSTR.(false))
      next_instr = flow[:instr] # nil when EOF
      return flow
    }

    flow = flow.next _ARG_LOOP
    return flow[:error] = "Expected instruction name, got #{flow.tc.sneak_peek.type}" if instr_name.nil?
    return flow.next _ON_NEWLINE if flow[:line_crossed]
    flow = flow.next EAT_CLOSE_BRACE
    return flow if flow.ok?
  
    flow = flow.next _MOD_LOOP
    return flow.next _ON_NEWLINE if flow[:line_crossed]
    flow = flow.next EAT_CLOSE_BRACE
    return flow if flow.ok?

  }.curry

  def parse token_consumer
    
  end
end