require 'socket'

module DB
  class Connection
    MAX_LENGTH = 1_000.freeze

    def initialize
      @db_sock, @main_sock = Socket.pair(:UNIX, :DGRAM, 0)

      fork do
        require './sqlord/driver'

        @main_sock.close
        driver = SQLord::Driver.new

        request  = @db_sock.recv(MAX_LENGTH)
        response = driver.translate(request)

        @db_sock.send(response, 0)
      end

      @db_sock.close
    end

    def exec(message)
      write(message)

      read
    end

    def write(message)
      @main_sock.send(message, 0)
    end

    def read
      @main_sock.recv(MAX_LENGTH)
    end

    def close
      @main_sock.close
    end
  end
end
