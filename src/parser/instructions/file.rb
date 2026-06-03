def file path, isAppend, ctx
  if isAppend
    ctx.remaining += File.read(path)
  else
    ctx.remaining = File.read(path)
  end
end