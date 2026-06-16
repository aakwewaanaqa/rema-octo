module Instructions
  class Exit
    def self.check args, mods = nil, val = nil, &block
      nil
    end

    def self.call args, mods = nil, val = nil, &block
      exit 0
    end
  end
end
