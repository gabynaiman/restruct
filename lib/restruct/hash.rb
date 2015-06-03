module Restruct
  class Hash < Structure

    include Enumerable
    extend Forwardable

    def_delegators :to_h, :merge, :flatten, :invert

    def [](key)
      deserialize connection.call('HGET', id, key)
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
      connection.call 'HSET', id, key, serialize(value)
      value
    end
    alias_method :[]=, :store

    def update(hash)
      hash.each { |k,v| store k, v }
      self
    end
    alias_method :merge!, :update

    def delete(key)
      value = self[key]
      connection.call 'HDEL', id, key
      value
    end

    def delete_if
      each { |k,v| delete k if yield k, v }
      self
    end

    def keep_if
      each { |k,v| delete k unless yield k, v }
      self
    end
    alias_method :select!, :keep_if

    def clear
      destroy
      self
    end

    def keys
      connection.call 'HKEYS', id
    end

    def values
      connection.call('HVALS', id).map { |v| deserialize v }
    end

    def values_at(*keys)
      keys.map { |k| self[k] }
    end

    def key?(key)
      connection.call('HEXISTS', id, key) == 1
    end
    alias_method :has_key?, :key?

    def value?(value)
      values.include? value
    end
    alias_method :has_value?, :value?

    def size
      connection.call 'HLEN', id
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
      connection.call('HGETALL', id).each_slice(2).each_with_object({}) do |(k,v), hash|
        hash[k] = deserialize v
      end
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