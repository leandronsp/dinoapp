require 'rack'
require './db/connection'
require 'json'
require 'byebug'

class App
  def call(env)
    request  = Rack::Request.new(env)
    status, headers, body = process_request(request)

    [status, headers.merge('Content-Type' => 'text/html'), body]
  end

  private

  def process_params(request)
    request_params = request.params
    body_params    = request.post? ? (JSON.parse(request.body.read) rescue {}) : {}

    request_params.merge(body_params)
  end

  def process_request(request)
    verb    = request.request_method
    path    = request.path
    params  = process_params(request)
    headers = request.env
    cookies = request.cookies

    response_status  = 200
    response_headers = {}
    response_body    = ''

    case [request.request_method, request.path]
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
      status = 200

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

    [response_status, response_headers, response_body]
  end
end
