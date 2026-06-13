module Instructions
  EXCEPTION_MESSAGES = {
    Errno::ENOENT  => "Path does not exist",
    Errno::ENOTDIR => "Not a directory",
    Errno::EACCES  => "Permission denied",
    Errno::EEXIST  => "File already exists",
  }

  SAFE_EXEC = -> fix, &block {
    { ok: true, result: block.() }
  rescue => e
    message = EXCEPTION_MESSAGES[e.class] || e.message
    { ok: false, error: { code: e.class.name, message: message }, fix: fix }
  }

  REGISTRY = {}
end

require_relative "instructions/cd"
