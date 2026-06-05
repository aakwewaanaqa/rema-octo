module Parse
  def parse_instr_colon_token consumer, ctx
    text = ''
    next_instr_colon = nil

    while peak = consumer.advance!
      if consumer.literaling
        text += peak
        next
      end

      if peak == ':'
        next_instr_colon = parse_instr_colon_token consumer, ctx
        break
      end

      text += peak
    end

    parts = split_the_text_by_space text.strip
    next_instr_colon = nil if next_instr_colon && next_instr_colon[:name].nil?
    return {
      text:             text,
      name:             parts[0],
      args:             parts[1..],
      next_instr_colon: next_instr_colon,
    }
  end

  def parse_instr_token consumer, ctx
    text = ''
    piped_instr_token       = nil
    next_instr_token        = nil
    block_token             = nil
    colon_tokens            = nil
    expect_next_instr_first = false

    candidates = ['|>', '{', '}', "\r", "\n", " ", "\t", '_ANY_CHAR_']
    while peak = consumer.match_and_advance!(candidates)
      if consumer.literaling
        text += peak
        next
      end

      if peak == '}'
        if ctx[:inBlock]
          break
        else
          ctx[:error] = { readable_pos: consumer.readable_pos, message: "Unexpected '}'" }
          break
        end
      end

      if peak == '|>'
        piped_instr_token = parse_instr_token consumer, ctx
        break
      end

      if peak == '{'
        block_token = parse_instr_token consumer, ctx.merge(inBlock: true)
        next
      end

      break if peak.nil?
    
      if peak == "\n" || peak == "\r" || expect_next_instr_first
        expect_next_instr_first = true
        next if consumer.match_sneak_peak?(["\n", "\r", " ", "\t"])
        next_instr_token = parse_instr_token consumer, ctx
        break
      end

      text += peak
    end

    colons_consumer = StringConsumer.new text
    colons_consumer.readable_pos_offset = consumer.readable_pos
    colon_tokens = parse_instr_colon_token colons_consumer, {}

    return {
      colon_tokens:      colon_tokens,
      piped_instr_token: piped_instr_token,
      next_instr_token:  next_instr_token,
      block_token:       block_token,
    }
  end
end