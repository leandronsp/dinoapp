require 'socket'
require 'rack'
require 'cgi'
require 'stringio'
require 'byebug'

class Server
  def initialize(rack_app, port)
    @rack_app = rack_app
    @port     = port
    @socket   = Socket.new(:INET, :STREAM)
    addr      = Socket.sockaddr_in(@port, '0.0.0.0')

    @socket.bind(addr)
    @socket.listen(2)

    puts "Listening to the port #{@port}..."
  end

  def self.run(*args)
    new(*args).run
  end

  def run
    loop do
      # Wait for a new TCP connection..."
      client, _ = @socket.accept

      # Request
      request = ''
      headers = {}
      body    = ''
      params  = {}
      cookies = {}

      request_verb = ''
      request_path = ''

      while line = client.gets
        break if line == "\r\n"

        # Extract Request verb and path
        if line.match(/HTTP\/.*?/)
          request_verb, request_path, _ = line.split
        end

        request += line

        # Request headers
        header_key, header_value = line.split(': ')
        headers[header_key] = header_value
      end

      puts request
      puts "\n"

      # Request body
      content_length = headers['Content-Length']
      body = client.read(content_length.to_i) if content_length

      # Extract params from body
      body_parts = body.split('&')
      params = body_parts
        .map { |part| part.split('=').map(&CGI.method(:unescape)) }
        .to_h

      # Request cookies
      if cookie = headers['Cookie']
        cookies =
          cookie
          .split(';')
          .map { |pair| pair.split('=') }
          .map { |(name, value)| [name.strip, CGI.unescape(value.gsub(/\r\n/, ''))] }
          .to_h
      end

      # Routing Response
      rack_data = {
        'REQUEST_METHOD' => request_verb,
        'PATH_INFO' => request_path.split('?')[0],
        'QUERY_STRING' => request_path.split('?')[1],
        'SERVER_PORT' => @port,
        'CONTENT_LENGTH' => content_length,
        'HTTP_COOKIE' => headers['Cookie'].gsub(/\r\n/, ''),
        'rack.input' => StringIO.new(body)
      }

      headers.each do |(name, value)|
        rack_data[name] = value.gsub(/\r\n/, '') if value
      end

      response_status, response_headers, response_body = @rack_app.call(rack_data)

      response_headers_str =
        response_headers.reduce('') do |acc, (key, value)|
          acc += "#{key}: #{value}\r\n"; acc
        end

      response = "HTTP/2.0 #{response_status}\r\n#{response_headers_str}\r\n#{response_body}"

      client.puts(response.strip.gsub(/\n+/, "\n"))

      # Close connection
      client.close
    end
  end
end
