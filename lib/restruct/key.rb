module Restruct
  class Key < String
    
    attr_reader :separator

    def initialize(key, separator=nil)
      @separator = separator || Restruct.key_separator
      super key.to_s
    end

    def [](key)
      Key.new "#{to_s}#{separator}#{key}", separator
    end

    def sections
      split(separator).map { |s| Key.new s, separator }
    end

  end
end