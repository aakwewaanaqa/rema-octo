module Oppl
  module Instructions
    def self.to_pattern(s)
      r = Shared::Convert::TRY_AS_REGEXP.(s)
      r.ok ? r.val : s
    end
  end
end
