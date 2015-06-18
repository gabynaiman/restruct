module Restruct
  class Connection

    attr_reader :redis
   
    def initialize(*args)
      @redis = Redic.new *args
      @scripts = {}
    end

    def call(*args)
      raise ArgumentError if args.empty?
      result = redis.call! *args
    rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL => ex
      retry
    rescue RuntimeError => ex
      raise ConnectionErrorFactory.create(ex)
    end

    def script(lua_src, *args)
      @scripts[lua_src] ||= call 'SCRIPT', 'LOAD', lua_src
      call 'EVALSHA', @scripts[lua_src], *args
    rescue NoScriptError
      @scripts.delete lua_src
      retry
    end

    def url
      redis.url
    end

  end
end