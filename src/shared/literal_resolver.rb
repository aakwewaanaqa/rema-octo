module Shared
  class LiteralResolver
    attr_reader :chuncks

    def initialize pure_string_with_quote
      sc = Shared::StringConsumer.new pure_string_with_quote[1..-2]
      chuncks = []
      cache = ''
      branch_tag = nil
      while peak = sc.sneak_peek
        # detect begining of code
        if !sc.literaling && !branch_tag && match = sc.match_advance(/(.)\{/)
          chuncks << {last: :txt, txt: cache} unless cache.empty?
          cache = ''
          branch_tag = match.captures[0].to_sym
          next
        end
        # detect end of code
        if !sc.literaling && branch_tag && sc.str_advance('}')
          chuncks << {last: branch_tag, txt: cache} unless cache.empty?
          cache = ''
          branch_tag = nil
          next
        end
        
        cache += sc.advance
      end
      # push last cached into chunks
      chuncks << {last: branch_tag || :txt, txt: cache} unless cache.empty?
      @chuncks = chuncks
    end

    def resolve(vars = {})
      chuncks.map do |chunk|
        case chunk[:last]
        when :txt  then chunk[:txt]
        when :"#"  then eval_ruby(chunk[:txt], vars)
        when :"!"  then `#{chunk[:txt]}`.chomp
        end
      end.join
    end

    private

    def eval_ruby(code, vars)
      b = binding
      vars.each { |k, v| b.local_variable_set(k, v) }
      b.eval(code)
    end
  end
end