module Restruct
  class Hash < Structure

    include Enumerable
    extend Forwardable

    def_delegators :to_h, :merge, :flatten, :invert

    def [](key)
      deserialize redis.call('HGET', id, key)
    end

    def fetch(key, default=nil, &block)
      if key? key
        self[key]
      else
        raise KeyError, "key not found: #{key}" if default.nil? && block.nil?
        default || block.call(key)
      end
    end

    def key(value)
      index = values.index value
      keys[index] if index
    end

    def store(key, value)
      redis.call 'HSET', id, key, serialize(value)
      value
    end
    alias_method :[]=, :store

    def delete(key)
      value = self[key]
      redis.call 'HDEL', id, key
      value
    end

    def delete_if
      each { |k,v| delete k if yield k, v }
      self
    end

    def clear
      destroy
      self
    end

    def keys
      redis.call 'HKEYS', id
    end

    def values
      redis.call('HVALS', id).map { |v| deserialize v }
    end

    def values_at(*keys)
      keys.map { |k| self[k] }
    end

    def key?(key)
      redis.call('HEXISTS', id, key) == 1
    end
    alias_method :has_key?, :key?

    def value?(value)
      values.include? value
    end
    alias_method :has_value?, :value?

    def size
      redis.call 'HLEN', id
    end
    alias_method :count, :size
    alias_method :length, :size

    def empty?
      size == 0
    end

    def each
      keys.each { |key| yield key, self[key] }
    end
    alias_method :each_pair, :each

    def each_key
      each { |k,v| yield k }
    end

    def each_value
      each { |k,v| yield v }
    end

    def to_h
      ::Hash[redis.call('HGETALL', id).each_slice(2).to_a]
    end
    alias_method :to_primitive, :to_h

    private

    def serialize(string)
      string
    end

    def deserialize(string)
      string
    end

  end
end