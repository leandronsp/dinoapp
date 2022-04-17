require 'json'
require './sqlord/tables/user'

module SQLord
  class Driver
    def translate(message)
      data = JSON.parse(message)
      table, action, args = data.values_at('table', 'action', 'args')

      Object
        .const_get("SQLord::Tables::#{table}")
        .send(action.to_sym, *args)
        .to_json
    end
  end
end
