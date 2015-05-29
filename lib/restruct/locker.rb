module Restruct
  class Locker < Structure

    REGISTER_LUA   = File.read '...'
    UNREGISTER_LUA = File.read '...'

    class Error < StandardError
      attr_reader :message

      def initialize(message)
        @message = message
      end
    end

    def lock(key, &block)
      _lock key, false, &block
    end

    def lock!(key, &block)
      _lock key, true, &block
    end

    alias_method :unlock!, :destroy

    alias_method :locked?, :exists?

    def key
      redis.call('HGET', id, 'key')
    end
    alias_method :locked_by, :key

    def to_h
      ::Hash[redis.call('HGETALL', id).each_slice(2)]
    end
    alias_method :to_primitive, :to_h
    
    private

    def _lock(key, exclusive)
      redis.script REGISTER_LUA,   0, id, key, exclusive
      yield
      redis.script UNREGISTER_LUA, 0, id, key, exclusive
    
    rescue Connection::ScriptError => ex
      raise Error, ex.message
    end

  end
end