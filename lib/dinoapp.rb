require 'rack'
require 'json'

require './config/db/connection'
require './app/controllers/base_controller'
Dir['./app/controllers/*.rb'].each {|file| require file }

require './config/routes'

class Dinoapp
  class Request
    attr_reader :verb, :path, :headers, :params, :cookies

    def initialize(verb, path, headers: {}, params: {}, cookies: {})
      @verb = verb
      @path = path

      @headers = headers
      @params  = params
      @cookies = cookies
    end

    def self.build(env)
      rack_request = Rack::Request.new(env)

      body_params = rack_request.post? ? (JSON.parse(rack_request.body.read) rescue {}) : {}
      params = rack_request.params.merge(body_params)

      new(
        rack_request.request_method,
        rack_request.path,
        headers: rack_request.env,
        params: params,
        cookies: rack_request.cookies
      )
    end
  end

  def call(env)
    request = ::Dinoapp::Request.build(env)

    Routes.lookup(request)
  end
end
