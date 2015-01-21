module Restruct
  class Id < String
    
    attr_reader :separator

    def initialize(id, separator=nil)
      @separator = separator || Restruct.id_separator
      super id.to_s
    end

    def [](id)
      Id.new "#{to_s}#{separator}#{id}", separator
    end

    def sections
      split(separator).map { |s| Id.new s, separator }
    end

  end
end