
module Instructions
  class Write
    def self.check args, mods, val, ctx, &block
    end
    
    def self.call args, mods, val, ctx, &block
      path = args[0]
      mode = (mods[:mode] || :replace).to_sym
      _to_s = val.to_s
      case mode
      when :replace
        IO.write path, _to_s
      when :append
        offset = File.size path
        IO.write path, _to_s, offset
      end

      _to_s
    end
  end
end