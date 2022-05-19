class SessionsController < BaseController
  def destroy
    redirect({
      'Set-Cookie' => 'email=; path=/; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
      'Location' => "http://#{@request.headers['Host']}/"
    })
  end

  def create
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
end
