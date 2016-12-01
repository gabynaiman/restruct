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
  
  let(:counter_hash) { CounterHash.new }

  describe 'Getters' do
    
    it '[]' do
      counter_hash[:a].current.must_equal 0
    end

    it 'fetch' do
      counter_hash[:a].incr

      counter_hash.fetch(:a).current.must_equal 1

      error = proc { counter_hash.fetch(:c) }.must_raise KeyError
      error.message.must_equal 'key not found: c'
    end
    
    it 'keys' do
      counter_hash[:a].incr
      counter_hash[:b].incr
      
      counter_hash.keys.must_equal %w(a b)
    end

    it 'values' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      counter_hash.values.map(&:current).must_equal [2, 1]
    end

    it 'values_at' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      counter_hash.values_at(:a, :f, :b, :g).map(&:current).must_equal [2, 0, 1, 0]
    end

  end

  describe 'Setters' do
    
    it 'delete' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      counter_hash.delete(:a)

      counter_hash.keys.must_equal %w(b)
    end
    
    it 'delete_if' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      counter_hash.delete_if { |k,v| v.current > 1 }.must_equal counter_hash
      counter_hash.keys.must_equal %w(b)
    end

    %w(keep_if select!).each do |method|
      it method do
        counter_hash[:a].incr.incr
        counter_hash[:b].incr

        counter_hash.send(method) { |k,v| v.current > 1 }.must_equal counter_hash
        counter_hash.keys.must_equal %w(a)
      end
    end
    
    it 'clear' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      counter_hash.clear.must_equal counter_hash
      counter_hash.must_be_empty
    end

  end

  describe 'Info' do

    %w(size count length).each do |method|
      it method do
        counter_hash[:a].incr.incr
        counter_hash[:b].incr

        counter_hash.send(method).must_equal 2
      end
    end
    
    it 'empty?' do
      counter_hash.must_be :empty?
      counter_hash[:a].incr
      counter_hash.wont_be :empty?
    end

    %w(key? has_key?).each do |method|
      it method do
        counter_hash[:a].incr.incr
        counter_hash[:b].incr

        assert counter_hash.send(method, :a)
        refute counter_hash.send(method, :c)
      end
    end

  end

  describe 'Transformations' do

    %w(to_h to_primitive).each do |method|
      it method do
        counter_hash[:a].incr.incr
        counter_hash[:b].incr

        counter_hash.send(method).must_equal 'a' => 2, 'b' => 1
      end
    end

  end

  describe 'Enumerable' do

    it 'included module' do
      assert Restruct::Hash.included_modules.include? Enumerable
    end

    %w(each each_pair).each do |method|
      it method do
        counter_hash[:a].incr.incr
        counter_hash[:b].incr

        keys = []
        values = []
        counter_hash.send(method) do |k,v|
          keys << k
          values << v
        end

        keys.must_equal counter_hash.keys
        values.must_equal counter_hash.values
      end
    end
    
    it 'each_key' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      keys = []
      counter_hash.each_key { |k| keys << k }

      keys.must_equal counter_hash.keys
    end
    
    it 'each_value' do
      counter_hash[:a].incr.incr
      counter_hash[:b].incr

      values = []
      counter_hash.each_value { |v| values << v }

      values.must_equal counter_hash.values
    end

  end

  it 'Equality' do
    copy = CounterHash.new id: counter_hash.id
    assert counter_hash == copy
    assert counter_hash.eql? copy
    refute counter_hash.equal? copy
  end

  it 'Dump/Restore' do
    counter_hash[:a].incr.incr
    counter_hash[:b].incr
    
    dump = counter_hash.dump
    other = CounterHash.new
    other.restore dump

    other.id.wont_equal counter_hash.id
    other.to_primitive.must_equal counter_hash.to_primitive
  end

end