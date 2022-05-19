require 'socket'
require 'cgi'
require 'json'
require './db/connection'

PORT = 3000
socket = TCPServer.new('0.0.0.0', PORT)

puts "Listening to the port #{PORT}..."

loop do
  # Wait for a new TCP connection..."
  client = socket.accept

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
  response_headline = "HTTP/2.0"
  response_status   = 200
  response_headers  = { 'Content-Type' => 'text/html' }

  case [request_verb, request_path]
  in 'POST', '/logout'
    response_status = 301

    response_headers['Set-Cookie'] = "email=; path=/; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
    response_headers['Location'] = "http://#{headers['Host']}/"
  in 'POST', '/login'
    email = params['email']
    password = params['password']

    query = <<-SQL
      SELECT * FROM users
      WHERE email = '#{email}' AND password = '#{password}'
    SQL

    connection = DB::Connection.new
    result = connection.execute(query)

    if result && result != 'null' && !result.empty?
      # Login succeeded
      response_status = 301

      response_headers['Set-Cookie'] = "email=#{email}; path=/; HttpOnly"
      response_headers['Location'] = "http://#{headers['Host']}/"
    else
      # Incorrect Email/Password
      response_status = 401
      response_body = File.read('./web/html/unauthorized.html')
    end
  in 'GET', '/'
    # Display Homepage
    if email = cookies['email']
      view = File.read('./web/html/home.html')
      response_body = view.gsub(/{{email}}/, email)
    else
      response_body = File.read('./web/html/login.html')
    end
  else
    # Not Found
    response_status = 404
    response_body = File.read('./web/html/not_found.html')
  end

  response_headers_str =
    response_headers.reduce('') do |acc, (key, value)|
      acc += "#{key}: #{value}\r\n"; acc
    end

  response = "#{response_headline} #{response_status}\r\n#{response_headers_str}\r\n#{response_body}"

  client.puts(response.strip.gsub(/\n+/, "\n"))

  # Close connection
  client.close
end
