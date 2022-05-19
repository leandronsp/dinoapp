require './db/connection'

class Actions
  def initialize(request)
    @request  = request
  end

  def self.proxy(action, request)
    new(request).send(action.to_sym)
  end

  def logout
    redirect({
      'Set-Cookie' => 'email=; path=/; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
      'Location' => "http://#{@request.headers['Host']}/"
    })
  end

  def login
    email    = @request.params['email']
    password = @request.params['password']

    query = <<-SQL
      SELECT * FROM users
      WHERE email = '#{email}' AND password = '#{password}'
    SQL

    connection = DB::Connection.new
    result = connection.execute(query)

    return unauthorized if result.nil? || result.empty?

    redirect({
      'Set-Cookie' => "email=#{email}; path=/; HttpOnly",
      'Location' => "http://#{@request.headers['Host']}/"
    })
  end

  def homepage
    email = @request.cookies['email']
    return success(default_header, view('login')) unless email

    body = view('home').gsub(/{{email}}/, email)
    success(default_header, body)
  end

  def not_found    = [404, default_header, not_found_view]
  def unauthorized = [401, default_header, unauthorized_view]

  private

  def success(headers, body) = [200, headers, body]
  def redirect(headers)     = [301, headers, '']

  def default_header = { 'Content-Type' => 'text/html' }

  def not_found_view    = view('not_found')
  def unauthorized_view = view('unauthorized')
  def view(name)        = File.read("./web/html/#{name}.html")
end
