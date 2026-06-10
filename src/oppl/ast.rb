module Ast
  class AstFlowResult
    attr_reader :tc, :data

    def initialize tc, data
      @tc = tc
      @data = data
    end

    def ok?
      return @data[:ok]
    end

    def if_ok(fn = nil, &block)
      callable = fn || block
      ok? ? callable.call(self) : self
    end

    def if_fail(fn = nil, &block)
      callable = fn || block
      ok? ? self : callable.call(self)
    end

    def next(fn = nil, &block)
      callable = fn || block
      callable.call(self)
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
      :type => 'EAT_LEADING_SPACE',
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
      :type => 'EAT_NAME',
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
      :type => 'EAT_PIPE',
      :ok => ok
    })
  }

  EAT_INSTR = -> flow {
    instr_name = ''
    pipe_instr = nil

    flow
    .next(EAT_LEADING_SPACE).next(EAT_NAME).if_ok { |flow| 
      instr_name = flow.data.name 
      flow
    }.next(EAT_LEADING_SPACE).next(EAT_PIPE).if_ok { |flow| 
      pipe_instr = EAT_INSTR.call(flow).data
      flow
    }.next()
  }

  def parse token_consumer
    
  end
end