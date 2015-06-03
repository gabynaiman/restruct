module Restruct
  class Batch
    class << self

      def execute(connection=nil)
        connection ||= Restruct.connection
        multi connection
        result = yield
        exec connection
        result
      rescue => ex
        discard connection
        raise ex
      end

      private

      def nesting
        @nesting ||= ::Hash.new { |h,k| h[k] = 0 }
      end

      def multi(connection)
        connection.call 'MULTI' if nesting[connection] == 0
        nesting[connection] += 1
      end

      def exec(connection)
        nesting[connection] -= 1
        connection.call 'EXEC' if nesting[connection] == 0
      end

      def discard(connection)
        nesting[connection] -= 1
        connection.call 'DISCARD' if nesting[connection] == 0
      end

    end
  end
end