module Restruct
  class Structure

    attr_reader :connection, :id

    def initialize(options={})
      @connection = options[:connection] || Restruct.connection
      @id = Id.new options[:id] || Restruct.generate_id
    end

    def ==(object)
      object.class == self.class && 
      object.id == id && 
      object.connection == connection
    end
    alias_method :eql?, :==

    def dump
      connection.call 'DUMP', id
    end

    def restore(dump)
      destroy
      connection.lazy 'RESTORE', id, 0, dump
    end

    def destroy
      connection.lazy 'DEL', id
    end

    def exists?
      connection.call('EXISTS', id) == 1
    end
    
  end
end