module Restruct
  class Hash < Structure

    def [](field)
      deserialize redis.call('HGET', id, field)
    end

    def fetch(field, default=nil, &block)
      if key? field
        self[field]
      else
        raise KeyError, "key not found: #{field}" if default.nil? && block.nil?
        default || block.call(field)
      end
    end

    # def []=(field, value)
    #   redis.call 'HSET', id, field, value
    # end

    # def delete(field)
    #   value = self[field]
    #   redis.call 'HDEL', id, field
    #   value
    # end

    # def keys
    #   redis.call 'HKEYS', id
    # end

    # def values
    #   redis.call 'HVALS', id
    # end

    def key?(field)
      redis.call('HEXISTS', id, field) == 1
    end

    # def empty?
    #   redis.call('HLEN', id) == 0
    # end

    # def size
    #   redis.call 'HLEN', id
    # end
    # alias_method :count, :size
    # alias_method :length, :size

    # def each
    #   keys.each { |field| yield field, self[field] }
    # end

    # def each_with_object(object)
    #   keys.each { |field| yield [field, self[field]], object }
    #   object
    # end

    # def map
    #   keys.map { |field| yield field, self[field] }
    # end

    def to_h
      ::Hash[redis.call('HGETALL', id).each_slice(2).to_a]
    end
    # alias_method :to_primitive, :to_h

    private

    def serialize(string)
      string
    end

    def deserialize(string)
      string
    end

  end
end