module Shared
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

  EAT_SPACES = -> flow {
    ok = false
    while peak = flow.tc.sneak_peek
      break unless peak&.last == :spaces
      flow.tc.advance
      ok = true
    end
    AstFlowResult.new(flow.tc, { :last => 'EAT_SPACES', :ok => ok })
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
end