module Lsp
  class Server
    def initialize(handler)
      @handler = handler
    end

    def run
      $stdout.sync = true
      $stdin.binmode
      $stdout.binmode

      loop do
        header = read_header
        break if header.nil?

        length = header[/Content-Length:\s*(\d+)/i, 1]&.to_i
        next unless length

        body = $stdin.read(length)
        request = JSON.parse(body)

        response = @handler.handle(request)
        write_response(response) if response
      end
    end

    private

    def read_header
      header = ""
      loop do
        line = $stdin.gets
        return nil if line.nil?
        break if line.strip.empty?
        header += line
      end
      header.empty? ? nil : header
    end

    def write_response(response)
      body = JSON.generate(response.merge("jsonrpc" => "2.0"))
      $stdout.write("Content-Length: #{body.bytesize}\r\n\r\n#{body}")
    end
  end
end
