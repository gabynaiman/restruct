module Restruct
  class Structure

    attr_reader :redis, :id

    def initialize(options={})
      @redis = options[:redis] || Restruct.redis
      @id = Id.new options[:id] || Restruct.generate_id
    end

    def dump
      redis.call 'DUMP', id
    end

    def restore(dump)
      destroy
      redis.call 'RESTORE', id, 0, dump
    end

    def destroy
      redis.call 'DEL', id
    end
    
  end
end