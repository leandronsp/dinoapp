require 'sqlite3'

module DB
  class Connection
    def initialize
      @driver = SQLite3::Database.new('./db/dinoapp.db')
    end

    def execute(query)
      @driver.execute(query)
    end
  end
end
