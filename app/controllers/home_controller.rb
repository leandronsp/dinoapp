class HomeController < BaseController
  def index
    email = @request.cookies['email']
    return success(default_header, view('login')) unless email

    body = view('home').gsub(/{{email}}/, email)
    success(default_header, body)
  end
end
