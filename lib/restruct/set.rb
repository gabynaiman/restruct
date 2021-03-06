module Restruct
  class Set < Structure

    include Enumerable
    extend Forwardable

    def_delegators :to_set, :union, :|, :+, 
                            :intersection, :&, 
                            :difference, :-,
                            :proper_subset?, :subset?,
                            :proper_superset?, :superset?,
                            :^

    def add(member)
      _add member
      self
    end
    alias_method :<<, :add

    def add?(member)
      _add(member) == 0 ? nil : self
    end

    def merge(members)
      _add *members
      self
    end

    def delete(member)
      _delete member
      self
    end

    def delete?(member)
      _delete(member) == 0 ? nil : self
    end

    def subtract(members)
      _delete *members
      self
    end

    def delete_if
      each { |e| delete e if yield e }
      self
    end

    def keep_if
      each { |e| delete e unless yield e }
      self
    end
    alias_method :select!, :keep_if

    def clear
      destroy
      self
    end

    def size
      connection.call 'SCARD', id
    end
    alias_method :count, :size
    alias_method :length, :size

    def empty?
      size == 0
    end

    def include?(member)
      connection.call('SISMEMBER', id, serialize(member)) == 1
    end

    def each(&block)
      to_a.each(&block)
    end

    def to_a
      connection.call('SMEMBERS', id).map { |e| deserialize e }
    end

    def to_set
      to_a.to_set
    end
    alias_method :to_primitive, :to_set
    
    alias_method :<, :proper_subset?
    alias_method :<=, :subset?
    alias_method :>, :proper_superset?
    alias_method :>=, :superset?

    def intersect?(set)
      !disjoint? set
    end

    def disjoint?(set)
      (to_a & set.to_a).empty?
    end

    private

    def _add(*members)
      connection.lazy 'SADD', id, *members.map { |m| serialize m }
    end

    def _delete(*members)
      connection.lazy 'SREM', id, *members.map { |m| serialize m }
    end


    def serialize(string)
      string
    end

    def deserialize(string)
      string
    end

  end
end