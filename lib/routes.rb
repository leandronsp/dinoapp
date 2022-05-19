require './lib/actions'

class Routes
  ROUTES_TABLE = {
    'GET /'        => :homepage,
    'POST /logout' => :logout,
    'POST /login'  => :login
  }.freeze

  def self.lookup(request)
    action = ROUTES_TABLE["#{request.verb} #{request.path}"]

    return Actions.proxy(:not_found, request) unless action

    Actions.send(:proxy, action, request)
  end
end
