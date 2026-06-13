module Instructions
  REGISTRY['cd'] = -> args, mods, block_fn, pipe_val {
    path = args[0]
    return { ok: false, error: { code: "MISSING_ARG", message: "cd requires a path" }, fix: "cd <path>" } if path.nil?

    SAFE_EXEC.("Check that '#{path}' exists and is a directory") { Dir.chdir(path) }
  }
end
