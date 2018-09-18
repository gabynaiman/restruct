module Restruct
  class Cache < Structure

    include Enumerable

    attr_reader :ttl

    def initialize(options={})
      super options
      @ttl = options.fetch(:ttl)
    end

    def key?(key)
      connection.call('EXISTS', id[key]) == 1
    end
    alias_method :has_key?, :key?

    def keys
      sections = id.sections.count + 1
      connection.call('KEYS', id['*']).map do |k| 
        Id.new(k).sections.take(sections).last
      end.uniq.sort
    end

    def [](key)
      deserialize connection.call('GET', id[key])
    end

    def []=(key, value)
      connection.lazy 'SET', id[key], serialize(value)
      connection.lazy 'EXPIRE', id[key], ttl
    end

    def delete(key)
      value = self[key]
      connection.lazy 'DEL', id[key]
      value
    end

    def fetch(key, &block)
      if key? key
        connection.lazy 'EXPIRE', id[key], ttl
        self[key]
      else
        value = block.call
        self[key] = value
        value
      end
    end

    def each
      keys.each { |key| yield key, self[key] }
    end

    def size
      keys.count
    end
    alias_method :count, :size
    alias_method :length, :size

    def empty?
      size == 0
    end

    def to_h
      keys.each_with_object({}) do |key, hash|
        hash[key] = self[key]
      end
    end
    alias_method :to_primitive, :to_h
    alias_method :dump, :to_h

    def restore(dump)
      dump.each { |k,v| self[k] = v }
    end

    def destroy
      keys.each { |k| connection.lazy 'DEL', id[k] }
      self
    end
    alias_method :clear, :destroy

    private

    def serialize(string)
      string
    end

    def deserialize(string)
      string
    end

  end
end