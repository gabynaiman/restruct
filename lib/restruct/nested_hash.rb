module Restruct
  class NestedHash
    
    def self.new(type)
      Class.new Structure do
        
        const_set :TYPE, type

        def [](field)
          self.class::TYPE.new key: key[field], redis: redis, parent: self
        end

        def delete(field)
          self[field].tap(&:destroy)
        end

        def keys
          sections = key.sections.count + 1
          redis.call('KEYS', key['*']).map do |k| 
            Key.new(k).sections.take(sections).last
          end.uniq
        end

        def values
          keys.map { |field| self[field] }
        end

        def key?(field)
          keys.include? key[field]
        end

        def empty?
          size == 0
        end

        def size
          redis.call('KEYS', key['*']).count
        end
        alias_method :count, :size
        alias_method :length, :size

        def each
          keys.each { |field| yield field, self[field] }
        end

        def each_with_object(object)
          keys.each { |field| yield [field, self[field]], object }
          object
        end

        def map
          keys.map { |field| yield field, self[field] }
        end

        def to_h
          ::Hash[keys.map { |field| [field, self[field].to_primitive] }]
        end
        alias_method :to_primitive, :to_h

        def dump
          each_with_object({}) do |(field, value), hash|
            hash[field] = value.dump
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