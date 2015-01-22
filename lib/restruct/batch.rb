module Restruct
  class Batch
    class << self

      def execute(redis=nil)
        redis ||= Restruct.redis
        multi redis
        yield
        exec redis
      rescue => ex
        discard redis
        raise ex
      end

      private

      def nesting
        @nesting ||= ::Hash.new { |h,k| h[k] = 0 }
      end

      def multi(redis)
        redis.call 'MULTI' if nesting[redis] == 0
        nesting[redis] += 1
      end

      def exec(redis)
        nesting[redis] -= 1
        redis.call 'EXEC' if nesting[redis] == 0
      end

      def discard(redis)
        nesting[redis] -= 1
        redis.call 'DISCARD' if nesting[redis] == 0
      end

    end
  end
end