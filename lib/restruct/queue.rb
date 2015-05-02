module Restruct
  class Queue < Structure

    def push(object)
      redis.call 'RPUSH', id, serialize(object)
    end

    def pop
      deserialize redis.call('LPOP', id)
    end

    def size
      redis.call 'LLEN', id
    end
    alias_method :count, :size
    alias_method :length, :size

    def empty?
      size == 0
    end

    def to_a
      redis.call('LRANGE', id, 0, -1).map { |o| deserialize o }
    end
    alias_method :to_primitive, :to_a

    private

    def serialize(string)
      string
    end

    def deserialize(string)
      string
    end

  end
end