Dir[File.join(__dir__, 'instructions', '*.rb')].each { |f| require_relative f }
