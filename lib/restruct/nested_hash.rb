module Restruct
  class NestedHash
    
    def self.new(type)
      Class.new Structure do

        include Enumerable
        
        const_set :TYPE, type

        def [](key)
          self.class::TYPE.new id: id[key], connection: connection, parent: self
        end

        def fetch(key)
          raise KeyError, "key not found: #{key}" unless key? key
          self[key]
        end

        def delete(key)
          self[key].tap(&:destroy)
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
          sections = id.sections.count + 1
          connection.call('KEYS', id['*']).map do |k| 
            Id.new(k).sections.take(sections).last
          end.uniq.sort
        end

        def values
          keys.map { |key| self[key] }
        end

        def values_at(*keys)
          keys.map { |key| self[key] }
        end

        def key?(key)
          keys.include? key.to_s
        end
        alias_method :has_key?, :key?

        def size
          keys.count
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
          each_with_object({}) do |(key, value), hash|
            hash[key] = value.respond_to?(:to_primitive) ? value.to_primitive : value
          end
        end
        alias_method :to_primitive, :to_h

        def dump
          each_with_object({}) do |(key, value), hash|
            hash[key] = value.dump
          end
        end

        def restore(dump)
          dump.each { |f,d| self[f].restore d }
        end

        def destroy
          values.each(&:destroy)
        end

      end
    end

  end
end