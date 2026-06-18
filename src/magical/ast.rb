module Magical
  module Ast
    module Instr
      include Shared

      InstrNode = Struct.new(
        :name,
        :args,
        :next_instr,
      )

      EAT_SEPERATOR = -> flow {
        peak = flow.tc.sneak_peek
        case peak&.last
        when :semi_colon
          flow.tc.advance
          return AstFlowResult.new(flow.tc, {
            last: :semi_colon,
            ok: true
          })
        when :exclamation
          flow.tc.advance
          return AstFlowResult.new(flow.tc, {
            last: :exclamation,
            ok: true
          })
        when :question_mark
          flow.tc.advance
          return AstFlowResult.new(flow.tc, {
            last: :question_mark,
            ok: true
          })
        end

        AstFlowResult.new(flow.tc, {
          ok: false
        })
      }

      EAT_INSTR = -> flow {
        name = nil
        args = []
        next_instr = nil

        flow
          .subflow(-> flow {
            flow
            .pipe(-> f { EAT_SPACES.(f); EAT_NAME.(f).tap { |r| args << r[:name] if r[:ok] }; f })
            .terminate_if(-> flow { args.empty? })
            .pipe(NAME_SUB.(args))
            .pipe(EAT_SEPERATOR)
            .pipe(-> flow {
              if flow[:ok]
                case flow[:last]
                when :question_mark
                  name = :next_if_present
                  next_instr = EAT_INSTR.(flow)[:instr]
                when :exclamation
                  name = :rm_if_absent
                  next_instr = EAT_INSTR.(flow)[:instr]
                when :semi_colon
                  name = args[0]
                  args = args[1..-1]
                  next_instr = EAT_INSTR.(flow)[:instr]
                end
              else
                name = args[0]
                args = args[1..-1]
              end
              flow
          })})

        ok = !name.nil?
        AstFlowResult.new(flow.tc, {
          instr: ok ? InstrNode.new(
            name,
            args,
            next_instr
          ) : nil,
          ok: ok
        })
      }
    end

    module Stat
      include Shared
      include Magical::Ast::Instr

      StatNode = Struct.new(
        :code, 
        :instr, 
        :next_stat
      )

      EAT_STAT = -> tlc {
        return nil unless peak = tlc.advance

        code = peak[0].text

        tc = TokenConsumer.new(peak[1..-1])
        flow = AstFlowResult.new tc,{}
        instr = EAT_INSTR.(flow)[:instr]

        next_stat = EAT_STAT.(tlc)

        StatNode.new(
          code,
          instr,
          next_stat
        )
      }
    end
  end
end