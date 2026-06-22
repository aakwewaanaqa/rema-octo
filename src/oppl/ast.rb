module Oppl
  module Ast
    include Shared

    EAT_LEADING_SPACE = -> flow {
      ok = false
      line_crossed = false
      while peak = flow.tc.sneak_peek
        case peak.last
          when :comment
            flow.tc.advance
            ok = true
            line_crossed = true
          when :spaces
            flow.tc.advance
            ok = true
          when :new_line
            flow.tc.advance
            ok = true
            line_crossed = true
          else
            break
        end
      end
      AstFlowResult.new(flow.tc, {
        :last => 'EAT_LEADING_SPACE',
        :line_crossed => line_crossed,
        :ok => ok
      })
    }

    EAT_PIPE = -> flow {
      ok = false
      peak = flow.tc.sneak_peek
      if peak&.last == :pipe
        flow.tc.advance
        ok = true
      end
      AstFlowResult.new(flow.tc, { :last => 'EAT_PIPE', :ok => ok })
    }

    EAT_OPEN_BRACE = -> flow {
      ok = false
      peak = flow.tc.sneak_peek
      if peak&.last == :open_brace
        flow.tc.advance
        ok = true
      end
      AstFlowResult.new(flow.tc, { :last => 'EAT_OPEN_BRACE', :ok => ok })
    }

    EAT_CLOSE_BRACE = -> flow {
      ok = false
      peak = flow.tc.sneak_peek
      if peak&.last == :close_brace
        flow.tc.advance
        ok = true
      end
      AstFlowResult.new(flow.tc, { :last => 'EAT_CLOSE_BRACE', :ok => ok })
    }

    EAT_COLON = -> flow {
      ok = false
      peak = flow.tc.sneak_peek
      if peak&.last == :colon
        flow.tc.advance
        ok = true
      end
      AstFlowResult.new(flow.tc, { :last => 'EAT_COLON', :ok => ok })
    }

    module Instr
      include Shared

      class InstrNode
        attr_accessor :name, :args, :mods, :block_instr, :pipe_instr, :next_instr, :in_pipe

        def initialize in_pipe = false
          @name = nil
          @args = []
          @mods = {}
          @block_instr = nil
          @pipe_instr = nil
          @next_instr = nil
          @in_pipe = in_pipe
        end
      end

      ARG_SUB = -> instr_node, flow {
        flow
        .subflow(-> flow {
          flow
          .pipe(EAT_LEADING_SPACE)
          .terminate_if(-> flow { flow[:line_crossed] })
          .pipe(EAT_NAME)
          .terminate_if(-> flow { !flow.ok? }, -> flow { flow.make_error 'Expected instruction name' })
          .on_ok(-> flow { instr_node.name = flow[:name] })
          .pipe(NAME_SUB.(instr_node.args))
        })
      }.curry

      MOD_SUB = -> instr_node, flow {
        mod_key = nil
        mod_args = []
        flow
        .subflow(-> flow {
          flow
          .terminate_if(-> flow { flow.tc.sneak_peek&.last == :new_line })
          .pipe(EAT_SPACES) # dealing the first time coming into MOD_SUB
          .pipe(EAT_COLON)  # dealing the first time coming into MOD_SUB
          .pipe(EAT_SPACES) # dealing the first time coming into MOD_SUB
          .pipe(EAT_NAME)
          .terminate_if(-> flow { !flow.ok? })
          .on_ok(-> flow { mod_key = flow[:name].to_sym })
          .pipe(NAME_SUB.(mod_args))
          .on_ok(-> flow { instr_node.mods[mod_key] = mod_args })
          .pipe(EAT_SPACES)
          .pipe(EAT_COLON)
          .terminate_if(-> flow { !flow.ok? })
          .pipe(MOD_SUB.(instr_node))
        })
      }.curry

      REST_PART_SUB = -> instr_node, flow {
        eat_leading_space_again = false

        flow
        .pipe(EAT_SPACES)
        .subflow(-> flow {
          flow
          .pipe(EAT_OPEN_BRACE)
          .terminate_if(-> flow { !flow.ok? })
          .pipe(EAT_INSTR.(false))
          .on_ok(-> flow { instr_node.block_instr = flow[:instr] })
          .pipe(EAT_SPACES)
          .pipe(EAT_CLOSE_BRACE)
          .on_ok(-> flow { eat_leading_space_again = true })
        })
        .subflow(-> flow {
          flow
          .pipe_if(-> flow { eat_leading_space_again }, EAT_LEADING_SPACE)
          .pipe(EAT_PIPE)
          .terminate_if(-> flow { !flow.ok? })
          .pipe(EAT_INSTR.(true))
          .on_ok(-> flow { instr_node.pipe_instr = flow[:instr] })
          .on_ok(-> flow { eat_leading_space_again = true })
        })
        .subflow(-> flow {
          flow
          .terminate_if(-> flow { instr_node.in_pipe })
          .pipe(EAT_LEADING_SPACE)
          .terminate_if(-> flow { !flow[:line_crossed] })
          .pipe(EAT_INSTR.(false))
          .on_ok(-> flow { instr_node.next_instr = flow[:instr] })
        })
      }.curry

      EAT_INSTR = -> in_pipe, flow {
        node = InstrNode.new(in_pipe)
        error = nil

        flow
          .pipe(ARG_SUB.(node))
          .terminate_if(
            -> f { node.name.nil? },
            -> f { error = "Expected instruction name" }
          )
          .pipe(MOD_SUB.(node))
          .pipe(REST_PART_SUB.(node))

        AstFlowResult.new(flow.tc, {
          :last => 'EAT_INSTR',
          :ok => !node.name.nil? && error.nil?,
          :instr => node,
          :error => error ? { :message => error, :readable_pos => flow.tc.readable_pos } : nil
        })
      }.curry
    end
  end
end
