module Instructions
  class Ls
    def self.check args, mods, val, &block
      nil
    end
    
    def self.call args, mods, val, &block
      results = []
      Dir.each_child('.') { |item|
        results << item
      }
      results
    end
  end
end