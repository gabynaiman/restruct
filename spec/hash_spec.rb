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

    # it keys
    # it values
    # it values_at
  end

  describe 'Setters' do
    # it []=
    # it clear
    # it delete
    # it delete_if
    # it merge
    # it replace
    # it shift
    # it store
    # it update
  end

  describe 'Info' do
    # %w(size count length).each do |method|
    #   it method do
    #     fill %w(a b c)
    #     hash.send(method).must_equal 3
    #   end
    # end
    # it empty?
    # it key?
    # it has_key?
    # it has_value?
    # it value?
  end

  describe 'Transformations' do
    # it flatten
    # it invert
  end

  describe 'Enumerable' do
    # it each
    # it each_key
    # it each_pair
    # it each_value

    # it 'any?' do
    #   hash.any?.must_equal false
    #   fill %w(a b c)
    #   hash.any?.must_equal true
    #   array.any? { |e| e == 'a' }.must_equal true
    #   array.any? { |e| e == 'z' }.must_equal false
    # end

    # %w(detect find).each do |method|
    #   it method do
    #     fill %w(a1 b1 a2 b2)
    #     array.send(method) { |e| e.start_with? 'b' }.must_equal 'b1'
    #     array.send(method) { |e| e.start_with? 'x' }.must_be_nil
    #   end
    # end

    # %w(select find_all).each do |method|
    #   it method do
    #     fill %w(a1 b1 a2 b2)
    #     array.send(method) { |e| e.start_with? 'b' }.must_equal %w(b1 b2)
    #     array.send(method) { |e| e.start_with? 'x' }.must_equal []
    #   end
    # end

    # %w(map collect).each do |method|
    #   it method do
    #     fill %w(a1 b1 a2 b2)
    #     array.send(method) { |e| e[0] }.must_equal %w(a b a b)
    #   end
    # end

    # it 'sort' do
    #   fill %w(x3 a6 c4 y2 z1 b5)

    #   array.sort.must_equal %w(a6 b5 c4 x3 y2 z1)
    #   array.sort { |e1, e2| e1[1] <=> e2[1] }.must_equal %w(z1 y2 x3 c4 b5 a6)
    # end
  end

  # it 'Equality' do
  #   copy = klass.new id: array.id
  #   assert array == copy
  #   assert array.eql? copy
  # end
  
  # it 'Dump/Restore' do

end