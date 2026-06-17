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

    def make_error msg
      @data[:error] = {
        :message => msg,
        :readable_pos => @tc.readable_pos
      }
    end

    def on_ok fn
      return self if @data[:terminated]
      fn.call(self) if ok?
      self
    end

    def pipe_if_ok fn
      return self if @data[:terminated]
      ok? ? fn.call(self) : self
    end

    def pipe_if predicate, fn
      return self if @data[:terminated]
      predicate.(self) ? fn.call(self) : self
    end

    def terminate_if predicate, on_terminate = nil
      return self if @data[:terminated]
      @data[:terminated] = true if predicate.(self)
      if @data[:terminated] then on_terminate.(self) unless on_terminate.nil? end
      self
    end

    def pipe fn
      return self if @data[:terminated]
      fn.call(self)
    end

    def resume
      @data[:terminated] = false
      self
    end

    def subflow fn
      return self if @data[:terminated]
      fn.(AstFlowResult.new @tc, @data.dup)
      self
    end
  end

  EAT_LEADING_SPACE = -> flow {
    ok = false
    line_crossed = false
    while peak = flow.tc.sneak_peek
      case peak.last
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
    case peak&.last
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
    if peak&.last == :pipe
      flow.tc.advance
      ok = true
    end

    AstFlowResult.new(flow.tc, {
      :last => 'EAT_PIPE',
      :ok => ok
    })
  }

  EAT_OPEN_BRACE = -> flow {
    ok = false
    peak = flow.tc.sneak_peek
    if peak&.last == :open_brace
      flow.tc.advance
      ok = true
    end

    AstFlowResult.new(flow.tc, {
      :last => 'EAT_OPEN_BRACE',
      :ok => ok
    })
  }

  EAT_CLOSE_BRACE = -> flow {
    ok = false
    peak = flow.tc.sneak_peek
    if peak&.last == :close_brace
      flow.tc.advance
      ok = true
    end

    AstFlowResult.new(flow.tc, {
      :last => 'EAT_CLOSE_BRACE',
      :ok => ok
    })
  }

  EAT_SPACES = -> flow {
    ok = false
    while peak = flow.tc.sneak_peek
      break unless peak&.last == :spaces
      flow.tc.advance
      ok = true
    end
    AstFlowResult.new(flow.tc, { :last => 'EAT_SPACES', :ok => ok })
  }

  EAT_COLON = -> flow {
    ok = false
    peak = flow.tc.sneak_peek
    if peak&.last == :colon
      flow.tc.advance
      ok = true
    end

    AstFlowResult.new(flow.tc, {
      :last => 'EAT_COLON',
      :ok => ok
    })
  }

  module Instr
    class InstrNode
      attr_accessor :name, :args, :mods, :block_instr, :pipe_instr, :next_instr, :in_pipe

      def initialize in_pipe = false
        @name = nil
        @args = []
        @mods = {}
        @block_instr = nil
        @pipe_instr = nil
        @next_instr = nil
        @in_pipe = in_pipe
      end
    end

    NAME_SUB = -> array_to_push, flow {
      flow
      .subflow(-> flow {
        flow
        .pipe(EAT_SPACES)
        .terminate_if(-> flow { !flow.ok? })
        .pipe(EAT_NAME)
        .terminate_if(-> flow { !flow.ok? })
        .on_ok(-> flow { array_to_push << flow[:name] })
        .pipe(NAME_SUB.(array_to_push)) # Recursive Again
      })
    }.curry

    ARG_SUB = -> instr_node, flow {
      flow
      .subflow(-> flow {
        flow
        .pipe(EAT_LEADING_SPACE)
        .terminate_if(-> flow { flow[:line_crossed] })
        .pipe(EAT_NAME)
        .terminate_if(-> flow { !flow.ok? }, -> flow { flow.make_error 'Expected instruction name' })
        .on_ok(-> flow { instr_node.name = flow[:name] })
        .pipe(NAME_SUB.(instr_node.args))
      })
    }.curry

    MOD_SUB = -> instr_node, flow {
      mod_key = nil
      mod_args = []
      flow
      .subflow(-> flow {
        flow
        .terminate_if(-> flow { flow.tc.sneak_peek&.last == :new_line })
        .pipe(EAT_SPACES)
        .pipe(EAT_NAME)
        .terminate_if(-> flow { !flow.ok? })
        .on_ok(-> flow { mod_key = flow[:name].to_sym })
        .pipe(NAME_SUB.(mod_args))
        .on_ok(-> flow { instr_node.mods[mod_key] = mod_args })
        .pipe(EAT_SPACES)
        .pipe(EAT_COLON)
        .terminate_if(-> flow { !flow.ok? })
        .pipe(MOD_SUB.(instr_node)) # Recursive Again
      })
    }.curry

    REST_PART_SUB = -> instr_node, flow {
      eat_leading_space_again = false

      flow
      .pipe(EAT_SPACES)
      .subflow(-> flow {
        flow
        .pipe(EAT_OPEN_BRACE)
        .terminate_if(-> flow { !flow.ok? })
        .pipe(EAT_INSTR.(false))
        .on_ok(-> flow { instr_node.block_instr = flow[:instr] })
        .pipe(EAT_SPACES)
        .pipe(EAT_CLOSE_BRACE)
        .on_ok(-> flow { eat_leading_space_again = true })
      })
      .subflow(-> flow {
        flow
        .pipe_if(-> flow { eat_leading_space_again }, EAT_LEADING_SPACE)
        .pipe(EAT_PIPE)
        .terminate_if(-> flow { !flow.ok? })
        .pipe(EAT_INSTR.(true))
        .on_ok(-> flow { instr_node.pipe_instr = flow[:instr] })
        .on_ok(-> flow { eat_leading_space_again = true })
      })
      .subflow(-> flow {
        flow
        .terminate_if(-> flow { instr_node.in_pipe })
        .pipe(EAT_LEADING_SPACE)
        .terminate_if(-> flow { !flow[:line_crossed] })
        .pipe(EAT_INSTR.(false))
        .on_ok(-> flow { instr_node.next_instr = flow[:instr] })
      })
    }.curry

    EAT_INSTR = -> in_pipe, flow {
      node = InstrNode.new(in_pipe)
      error = nil

      flow
        .pipe(ARG_SUB.(node))
        .terminate_if(
          -> f { node.name.nil? },
          -> f { error = "Expected instruction name" }
        )
        .pipe(MOD_SUB.(node))
        .pipe(REST_PART_SUB.(node))

      AstFlowResult.new(flow.tc, {
        :last => 'EAT_INSTR',
        :ok => !node.name.nil? && error.nil?,
        :instr => node,
        :error => error ? { :message => error, :readable_pos => flow.tc.readable_pos } : nil
      })
    }.curry
  end
end