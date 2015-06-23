module Restruct
  class Locker < Structure

    REGISTER_LUA   = File.read "#{File.dirname(__FILE__)}/../../lua/register.lua"
    UNREGISTER_LUA = File.read "#{File.dirname(__FILE__)}/../../lua/unregister.lua"

    def lock(key, &block)
      _lock key, false, &block
    end

    def lock!(key, &block)
      _lock key, true, &block
    end

    alias_method :unlock!, :destroy

    alias_method :locked?, :exists?

    def key
      connection.call('HGET', id, 'key')
    end
    alias_method :locked_by, :key

    def to_h
      ::Hash[connection.call('HGETALL', id).each_slice(2).to_a]
    end
    alias_method :to_primitive, :to_h
    
    private

    def _lock(key, exclusive)
      connection.script REGISTER_LUA,   0, id, key, exclusive
      begin
        yield
      ensure  
        connection.script UNREGISTER_LUA, 0, id
      end      
    rescue Restruct::ConnectionError => ex
      raise LockerError.new ex
    end

  end
end