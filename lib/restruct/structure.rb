module Restruct
  class Structure

    attr_reader :redis, :key

    def initialize(options={})
      @redis = options[:redis] || Restruct.redis
      @key = Key.new options[:key] || Restruct.generate_key
    end

    def dump
      redis.call 'DUMP', key
    end

    def restore(dump)
      destroy
      redis.call 'RESTORE', key, 0, dump
    end

    def destroy
      redis.call 'DEL', key
    end
    
  end
end