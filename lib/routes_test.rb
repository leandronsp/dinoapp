require 'test/unit'
require './lib/routes'
require './lib/app'

class RoutesTest < Test::Unit::TestCase
  def test_simple_route
    routes = Routes.new
    request = ::App::Request.new('GET', '/')

    assert_equal "homepage action", routes.lookup('GET', '/', request)
  end

  def test_route_with_params
    routes = Routes.new
    request = ::App::Request.new('GET', '/', params: { 'test' => true })

    assert_equal "homepage action with true", routes.lookup('GET', '/', request)
  end
end
