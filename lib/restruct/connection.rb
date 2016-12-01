module Restruct
  class Connection

    def initialize(*args)
      @args = args
      @redis = Redic.new *args
      @scripts = {}
      @nesting = ::Hash.new { |h,k| h[k] = 0 }
    end

    def call(*args)
      raise ArgumentError if args.empty?
      redis.call! *args
    rescue RuntimeError => ex
      raise ConnectionErrorFactory.create(ex)
    end

    def lazy(*args)
      if nested?
        redis.queue *args
        nil
      else
        call *args
      end
    end

    def script(lua_src, *args)
      scripts[lua_src] ||= call 'SCRIPT', 'LOAD', lua_src
      call 'EVALSHA', scripts[lua_src], *args
    rescue NoScriptError
      scripts.delete lua_src
      retry
    end

    def batch
      incr_nesting
      begin
        result = yield
      ensure
        decr_nesting
      end
      commit unless nested?
    rescue => ex   
      redis.clear unless nested?
      raise ex
    end

    def read
      redis.client.read
    end

    def clone
      Connection.new *@args
    end

    private 

    attr_reader :redis, :scripts

    def nested?
      @nesting[Thread.current.object_id] > 0
    end

    def incr_nesting
      @nesting[Thread.current.object_id] += 1
    end

    def decr_nesting
      @nesting[Thread.current.object_id] -= 1
    end

    def commit
      results = redis.commit 
      error = results.detect { |r| r === RuntimeError }
      raise ConnectionErrorFactory.create(error) if error
      results
    end

  end
end