module Restruct
  class Set < Structure

    include Enumerable

    def add(member)
      redis.call 'SADD', id, member
    end
    alias_method :<<, :add

    def delete(member)
      redis.call 'SREM', id, member
    end

    def each(&block)
      to_a.each(&block)
    end

    def empty?
      redis.call('EXISTS', id) == 0
    end

    def count
      redis.call 'SCARD', id
    end

    def include?(member)
      redis.call('SISMEMBER', id, member) == 1
    end

    def to_a
      redis.call 'SMEMBERS', id
    end
    alias_method :to_primitive, :to_a

    def to_set
      to_a.to_set
    end
    
  end
end