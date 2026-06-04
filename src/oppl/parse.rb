Instr = Struct.new(:name, :params, :mods)

def parse_instr text
  name = ''
  params = []
  mods = {}
  split_the_text_by_delimiter(text, ':').each_with_index do |colon, i|
    stripped = colon.strip
    colon_splits = split_the_text_by_delimiter(stripped, ' ')
    return if colon_splits.empty?

    if i == 0
      name = colon_splits[0]
      params = colon_splits[1..-1]
    else
      mods[colon_splits[0]] = colon_splits[1..-1]
    end
  end

  return Instr.new(name, params, mods)
end

Pipe = Struct.new(:head, :tail)

def parse_chain text
  head = nil
  tail = []
  split_the_text_by_delimiter(text, '|>').each do |pipe|
    stripped = pipe.strip
    return if stripped.empty?

    instr = parse_instr stripped
    if head.nil?
      head = instr
    else
      tail << instr
    end
  end

  return Pipe.new(head, tail)
end