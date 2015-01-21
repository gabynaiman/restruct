require 'minitest_helper'

describe Restruct::Hash do

  let(:hash) { Restruct::Hash.new }

  def fill(data)
    redis.call 'HMSET', hash.id, *data.flatten
  end

  describe 'Getters' do
    
    it '[]' do
      fill a: 'x', b: 'y'

      hash[:a].must_equal 'x'
      hash[:b].must_equal 'y'
      hash[:c].must_be_nil
    end
    
    it 'fetch' do
      fill a: 'x', b: 'y'

      hash.fetch(:a).must_equal 'x'
      hash.fetch(:b).must_equal 'y'
      hash.fetch(:c, 'z').must_equal 'z'
      hash.fetch(:c) { |k| k.to_s }.must_equal 'c'
      
      error = proc { hash.fetch(:c) }.must_raise KeyError
      error.message.must_equal 'key not found: c'
    end
    
    it 'key' do
      fill a: 'x', b: 'y', c: 'y'

      hash.key('x').must_equal 'a'
      hash.key('y').must_equal 'b'
      hash.key('z').must_be_nil
    end

    it 'keys' do
      fill a: 'x', b: 'y', c: 'z'
      hash.keys.must_equal %w(a b c)
    end

    it 'values' do
      fill a: 'x', b: 'y', c: 'z'
      hash.values.must_equal %w(x y z)
    end

    it 'values_at' do
      fill a: 'x', b: 'y', c: 'z'
      hash.values_at(:a, :f, :b, :g, :c).must_equal ['x', nil, 'y', nil, 'z']
    end

  end

  describe 'Setters' do
    
    %w([]= store).each do |method|
      it method do
        fill a: 'x', b: 'y'

        hash.send(method, :a, 'a').must_equal 'a'
        hash.to_h.must_equal 'a' => 'a', 'b' => 'y'

        hash.send(method, :c, 'z').must_equal 'z'
        hash.to_h.must_equal 'a' => 'a', 'b' => 'y', 'c' => 'z'
      end
    end

    %w(update merge!).each do |method|
      it method do
        fill a: 'x', b: 'y'

        hash.send(method, a: 'a', c: 'z').must_equal hash
        hash.to_h.must_equal 'a' => 'a', 'b' => 'y', 'c' => 'z'
      end
    end
    
    it 'clear' do
      fill a: 'x', b: 'y'

      hash.clear.must_equal hash
      hash.to_h.must_equal Hash.new
    end
    
    it 'delete' do
      fill a: 'x', b: 'y'

      hash.delete(:b).must_equal 'y'
      hash.to_h.must_equal 'a' => 'x'
      
      hash.delete(:c).must_be_nil
      hash.to_h.must_equal 'a' => 'x'
    end
    
    it 'delete_if' do
      fill a: 'x', b: 'y'

      hash.delete_if { |k,v| v == 'x' }.must_equal hash
      hash.to_h.must_equal 'b' => 'y'
    end
    
  end

  describe 'Info' do

    %w(size count length).each do |method|
      it method do
        fill a: 'x', b: 'y'
        hash.send(method).must_equal 2
      end
    end
    
    it 'empty?' do
      hash.must_be :empty?
      fill a: 'x', b: 'y'
      hash.wont_be :empty?
    end

    %w(key? has_key?).each do |method|
      it method do
        fill a: 'x', b: 'y'

        assert hash.send(method, :a)
        refute hash.send(method, :c)
      end
    end
    
    %w(value? has_value?).each do |method|
      it method do
        fill a: 'x', b: 'y'

        assert hash.send(method, 'x')
        refute hash.send(method, 'z')
      end
    end

  end

  describe 'Transformations' do

    %w(to_h to_primitive).each do |method|
      it method do
        fill a: 'x', b: 'y'
        hash.send(method).must_equal 'a' => 'x', 'b' => 'y'
      end
    end

    it 'merge' do
      fill a: 'x', b: 'y'
      hash.merge('c' => 'z', 'a' => 'a').must_equal 'a' => 'a', 'b' => 'y', 'c' => 'z'
    end
    
    it 'flatten' do
      fill a: 'x', b: 'y'
      hash.flatten.must_equal %w(a x b y)
    end

    it 'invert' do
      fill a: 'x', b: 'y'
      hash.invert.must_equal 'x' => 'a', 'y' => 'b'
    end

  end

  describe 'Enumerable' do

    it 'included module' do
      assert Restruct::Hash.included_modules.include? Enumerable
    end

    %w(each each_pair).each do |method|
      it method do
        fill a: 'x', b: 'y'

        keys = []
        values = []
        hash.send(method) do |k,v|
          keys << k
          values << v
        end

        keys.must_equal hash.keys
        values.must_equal hash.values
      end
    end
    
    it 'each_key' do
      fill a: 'x', b: 'y'

      keys = []
      hash.each_key { |k| keys << k }

      keys.must_equal hash.keys
    end
    
    it 'each_value' do
      fill a: 'x', b: 'y'

      values = []
      hash.each_value { |v| values << v }

      values.must_equal hash.values
    end

  end

  it 'Equality' do
    copy = Restruct::Hash.new id: hash.id
    assert hash == copy
    assert hash.eql? copy
  end

  it 'Dump/Restore' do
    fill a: 'x', b: 'y'
    
    dump = hash.dump
    other = Restruct::Hash.new
    other.restore dump

    other.id.wont_equal hash.id
    other.to_h.must_equal hash.to_h
  end

end