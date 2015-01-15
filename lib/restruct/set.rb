module Restruct
  class Set < Structure

    include Enumerable

    def add(member)
      redis.call 'SADD', key, member
    end
    alias_method :<<, :add

    def delete(member)
      redis.call 'SREM', key, member
    end

    def each(&block)
      to_a.each(&block)
    end

    def empty?
      redis.call('EXISTS', key) == 0
    end

    def count
      redis.call 'SCARD', key
    end

    def include?(member)
      redis.call('SISMEMBER', key, member) == 1
    end

    def to_a
      redis.call 'SMEMBERS', key
    end
    alias_method :to_primitive, :to_a

    def to_set
      to_a.to_set
    end
    
  end
end