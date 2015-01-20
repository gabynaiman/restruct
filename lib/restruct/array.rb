module Restruct
  class Array < Structure

    include Enumerable
    extend Forwardable

    def_delegators :to_a, :uniq, :join, :reverse, :+, :-, :&, :|

    def at(index)
      redis.call 'LINDEX', key, index
    end

    def values_at(*args)
      args.each_with_object([]) do |arg, array|
        elements = self[arg]
        array.push *(elements ? Array(elements) : [nil])
      end
    end

    def fetch(index, default=nil, &block)
      validate_index_type! index

      if index < size
        at index
      else
        validate_index_bounds! index if default.nil? && block.nil?
        default || block.call(index)
      end
    end

    def [](*args)
      if args.count == 1
        if args.first.is_a? Integer
          at args.first.to_i
        elsif args.first.is_a? Range
          range args.first.first, args.first.last
        else
          validate_index_type! args.first
        end
      elsif args.count == 2
        range args[0], args[0] + args[1] - 1
      else
        raise ArgumentError, "wrong number of arguments (#{args.count} for 1..2)"
      end
    end

    def []=(index, element)
      validate_index_type! index
      validate_index_bounds! index

      redis.call 'LSET', key, index, element
    end

    def push(*elements)
      redis.call 'RPUSH', key, *elements
      self
    end
    
    def <<(element)
      push element
    end

    def insert(index, *elements)
      validate_index_type! index
      tail_size = index >= 0 ? size - index : size - (size + index) - 1
      tail = Array(pop(tail_size))
      push *(elements + tail)
    end

    def concat(array)
      push *array
    end

    def pop(count=1)
      if count == 1
        redis.call 'RPOP', key
      else
        [count, size].min.times.map { pop }.reverse
      end
    end

    def shift(count=1)
      if count == 1
        redis.call 'LPOP', key
      else
        [count, size].min.times.map { shift }
      end
    end

    def delete(element)
      removed_count = redis.call 'LREM', key, 0, element
      removed_count > 0 ? element : nil
    end

    def delete_at(index)
      validate_index_type! index
      return nil if out_of_bounds? index
      
      element = at index
      tail_size = index >= 0 ? size - index : size - (size + index)
      tail = Array(pop(tail_size))
      push *tail[1..-1]
      element
    end

    def delete_if
      each { |e| delete e if yield e }
      self
    end

    def clear
      destroy
      self
    end

    def size
      redis.call 'LLEN', key
    end
    alias_method :count, :size
    alias_method :length, :size

    def empty?
      size == 0
    end

    def each
      index = 0
      while index < size
        yield at(index)
        index += 1
      end
    end

    def each_index
      index = 0
      while index < size
        yield index
        index += 1
      end
    end

    def first
      at 0
    end

    def last
      at -1
    end

    def to_a
      range 0, -1
    end
    alias_method :to_ary, :to_a
    alias_method :to_primitive, :to_a

    private

    def range(start, stop)
      return nil if start > size
      redis.call 'LRANGE', key, start, stop
    end

    def validate_index_type!(index)
      raise TypeError, "no implicit conversion from #{index.nil? ? 'nil' : index.class.name.downcase} to integer" unless index.is_a? Integer
    end

    def validate_index_bounds!(index)
      raise IndexError, "index #{index} outside of array bounds: -#{size}...#{size}" if out_of_bounds? index
    end

    def out_of_bounds?(index)
      !(-size..size).include?(index)
    end

  end
end