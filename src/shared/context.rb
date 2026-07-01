module Shared
  class Context
    attr_accessor :vars

    def initialize(vars = {})
      @vars = vars
    end

    def [](key)
      @vars[key]
    end

    def []=(key, val)
      @vars[key] = val
    end

    def child
      c = self.class.new
      c.vars = @vars.dup
      c
    end
  end
end
