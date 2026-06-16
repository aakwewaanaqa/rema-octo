module Instructions
  class Cd
    def self.check args, mods, val, &block 
      return 'missing args[0]' if args.nil? || args.empty?
      nil
    end

    def self.call args, mods, val, &block 
      path = File.expand_path(args[0])
      Dir.chdir path
      Dir.pwd
    end
  end
end
