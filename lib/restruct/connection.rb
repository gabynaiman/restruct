module Restruct
  class Connection

    Error                = Class.new(StandardError)
    NoScriptError        = Class.new(Error)
    CompilingScriptError = Class.new(Error)
    ScriptError          = Class.new(Error)

    attr_reader :redis
   
    def initialize(*args)
      @redis = Redic.new *args
      @scripts = {}
    end

    def call(*args, &block)
      result = redis.call
      raise error_from(result) if result.is_a? ::RuntimeError
    end

    def script(lua_src, *args)
      @scripts[lua_src] ||= call 'SCRIPT', 'LOAD', lua_src
      call 'EVALSHA', @scripts[lua_src], *args
    rescue NoScriptError
      @scripts.delete lua_src
      retry
    end

  end
end