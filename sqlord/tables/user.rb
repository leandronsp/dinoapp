require 'csv'

module SQLord
  module Tables
    class User
      def initialize
        @rows = CSV.readlines('./sqlord/source/users.csv', col_sep: ';')
        @rows.shift
      end

      def self.method_missing(m, *args, &block)
        new.send(m, *args, &block)
      end

      def find_by_email_and_password(email, password)
        @rows.find do |row|
          row[0] == email && row[1] == password
        end
      end
    end
  end
end
