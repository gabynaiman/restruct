module Restruct
  class Error < StandardError
  end

  class ConnectionErrorFactory
    def self.create(exception)
      error_type = NoScriptError.match?(exception) ? NoScriptError : ConnectionError
      error_type.new exception
    end
  end

  class ConnectionError < Error

    def initialize(inner_exception)
      @inner_exception = inner_exception
    end

    def message
      @inner_exception.message
    end

    def backtrace
      @inner_exception.backtrace
    end

  end

  class NoScriptError < ConnectionError
    def self.match?(exception)
      exception.message.start_with? 'NOSCRIPT No matching script'
    end
  end

  class LockerError < Error

    def initialize(inner_exception)
      @inner_exception = inner_exception
    end

    def message
      @parsed_message ||= parse_message @inner_exception.message
    end

    def backtrace
      @inner_exception.backtrace
    end
    
    def parse_message(message)
      match_data = /^(ERR Error running script.*@user_script.*user_script.*: )/.match message
      match_data ? message.gsub(match_data.captures.first,'').strip : message
    end
  end

end