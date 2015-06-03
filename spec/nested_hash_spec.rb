require 'minitest_helper'

class Counter < Restruct::Structure
  def current
    (connection.call('GET', id) || 0).to_i
  end
  alias_method :to_primitive, :current

  def incr
    connection.call 'SET', id, current + 1
    self
  end
end

CounterHash = Restruct::NestedHash.new(Counter)


describe Restruct::NestedHash do
  
  let(:hash) { CounterHash.new }

  describe 'Getters' do
    
    it '[]' do
      hash[:a].current.must_equal 0
    end

    it 'fetch' do
      hash[:a].incr

      hash.fetch(:a).current.must_equal 1

      error = proc { hash.fetch(:c) }.must_raise KeyError
      error.message.must_equal 'key not found: c'
    end
    
    it 'keys' do
      hash[:a].incr
      hash[:b].incr
      
      hash.keys.must_equal %w(a b)
    end

    it 'values' do
      hash[:a].incr.incr
      hash[:b].incr

      hash.values.map(&:current).must_equal [2, 1]
    end

    it 'values_at' do
      hash[:a].incr.incr
      hash[:b].incr

      hash.values_at(:a, :f, :b, :g).map(&:current).must_equal [2, 0, 1, 0]
    end

  end

  describe 'Setters' do
    
    it 'delete' do
      hash[:a].incr.incr
      hash[:b].incr

      hash.delete(:a)

      hash.keys.must_equal %w(b)
    end
    
    it 'delete_if' do
      hash[:a].incr.incr
      hash[:b].incr

      hash.delete_if { |k,v| v.current > 1 }.must_equal hash
      hash.keys.must_equal %w(b)
    end

    %w(keep_if select!).each do |method|
      it method do
        hash[:a].incr.incr
        hash[:b].incr

        hash.send(method) { |k,v| v.current > 1 }.must_equal hash
        hash.keys.must_equal %w(a)
      end
    end
    
    it 'clear' do
      hash[:a].incr.incr
      hash[:b].incr

      hash.clear.must_equal hash
      hash.must_be_empty
    end

  end

  describe 'Info' do

    %w(size count length).each do |method|
      it method do
        hash[:a].incr.incr
        hash[:b].incr

        hash.send(method).must_equal 2
      end
    end
    
    it 'empty?' do
      hash.must_be :empty?
      hash[:a].incr
      hash.wont_be :empty?
    end

    %w(key? has_key?).each do |method|
      it method do
        hash[:a].incr.incr
        hash[:b].incr

        assert hash.send(method, :a)
        refute hash.send(method, :c)
      end
    end

  end

  describe 'Transformations' do

    %w(to_h to_primitive).each do |method|
      it method do
        hash[:a].incr.incr
        hash[:b].incr

        hash.send(method).must_equal 'a' => 2, 'b' => 1
      end
    end

  end

  describe 'Enumerable' do

    it 'included module' do
      assert Restruct::Hash.included_modules.include? Enumerable
    end

    %w(each each_pair).each do |method|
      it method do
        hash[:a].incr.incr
        hash[:b].incr

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
      hash[:a].incr.incr
      hash[:b].incr

      keys = []
      hash.each_key { |k| keys << k }

      keys.must_equal hash.keys
    end
    
    it 'each_value' do
      hash[:a].incr.incr
      hash[:b].incr

      values = []
      hash.each_value { |v| values << v }

      values.must_equal hash.values
    end

  end

  it 'Equality' do
    copy = CounterHash.new id: hash.id
    assert hash == copy
    assert hash.eql? copy
    refute hash.equal? copy
  end

  it 'Dump/Restore' do
    hash[:a].incr.incr
    hash[:b].incr
    
    dump = hash.dump
    other = CounterHash.new
    other.restore dump

    other.id.wont_equal hash.id
    other.to_primitive.must_equal hash.to_primitive
  end

end