require 'minitest_helper'

describe Restruct::StringArray do

  let(:array) { Restruct::StringArray.new }

  def fill(elements)
    redis.call 'RPUSH', array.key, *elements
  end

  describe 'Get elements' do

    it '[]' do
      fill %w(a b c d e)

      array[0].must_equal 'a'
      array[1].must_equal 'b'
      array[2].must_equal 'c'
      array[6].must_be_nil

      array[0..-1].must_equal %w(a b c d e)
      array[1..3].must_equal %w(b c d)
      array[4..7].must_equal ['e']
      array[5..10].must_equal []
      array[6..10].must_be_nil

      array[-3,3].must_equal %w(c d e)
      array[1,2].must_equal %w(b c)
      array[5,1].must_equal []
      array[6,1].must_be_nil
     
      error = proc { array[1,2,3,4] }.must_raise ArgumentError
      error.message.must_equal 'wrong number of arguments (4 for 1..2)'
     
      error = proc { array['x'] }.must_raise TypeError
      error.message.must_equal 'no implicit conversion from string to integer'
    end

    it 'at' do
      fill %w(a b c d)

      array.at(0).must_equal 'a'
      array.at(1).must_equal 'b'
      array.at(-1).must_equal 'd'
      array.at(10).must_be_nil
    end

    it 'values_at' do
      fill %w(a b c d e f)
      
      array.values_at(1, 3, 5).must_equal %w(b d f)
      array.values_at(1, 3, 5, 7).must_equal ['b', 'd', 'f', nil]
      array.values_at(-1, -2, -2, -7).must_equal ['f', 'e', 'e', nil]
    end

    it 'fetch' do
      fill %w(a b c)

      array.fetch(-1).must_equal 'c'
      array.fetch(0).must_equal 'a'
      array.fetch(4, 'x').must_equal 'x'
      array.fetch(4) { |i| (i + 1).to_s }.must_equal '5'
      
      error = proc { array.fetch(4) }.must_raise IndexError
      error.message.must_equal 'index 4 outside of array bounds: -3...3'
    end

    it 'first' do
      fill %w(a b c)
      array.first.must_equal 'a'
    end

    it 'last' do
      fill %w(a b c)
      array.last.must_equal 'c'
    end

  end

  describe 'Modify elements' do

    it '[]=' do
      fill %w(a b c d)

      (array[0] = 'x').must_equal 'x'
      array.to_a.must_equal %w(x b c d)

      (array[-1] = 'z').must_equal 'z'
      array.to_a.must_equal %w(x b c z)

      error = proc { array[10] = '.' }.must_raise IndexError
      error.message.must_equal 'index 10 outside of array bounds: -4...4'

      error = proc { array['k'] = '.' }.must_raise TypeError
      error.message.must_equal 'no implicit conversion from string to integer'
    end
    
    it 'push' do
      fill %w(a b c)
      
      array.push('d').must_equal array
      array.to_a.must_equal %w(a b c d)

      array.push('x', 'y', 'z').must_equal array
      array.to_a.must_equal %w(a b c d x y z)
    end

    it '<<' do
      fill %w(a b c)
      
      (array << 'd').must_equal array
      array.to_a.must_equal %w(a b c d)
    end

    it 'pop' do
      fill %w(a b c d e f)

      (array.pop).must_equal 'f'
      array.to_a.must_equal %w(a b c d e)

      (array.pop(2)).must_equal %w(d e)
      array.to_a.must_equal %w(a b c)

      (array.pop(5)).must_equal %w(a b c)
      array.to_a.must_equal []
    end

    it 'shift' do
      fill %w(a b c d e f)

      (array.shift).must_equal 'a'
      array.to_a.must_equal %w(b c d e f)

      (array.shift(2)).must_equal %w(b c)
      array.to_a.must_equal %w(d e f)

      (array.shift(5)).must_equal %w(d e f)
      array.to_a.must_equal []
    end

    it 'insert' do
      fill %w(a b c d)

      array.insert(0, 'A').must_equal array
      array.to_a.must_equal %w(A a b c d)

      array.insert(2, 'B', 'B').must_equal array
      array.to_a.must_equal %w(A a B B b c d)

      array.insert(-2, 'x', 'y', 'z').must_equal array
      array.to_a.must_equal %w(A a B B b c x y z d)

      array.insert(-5, 'w').must_equal array
      array.to_a.must_equal %w(A a B B b c w x y z d)      
    end

    it 'concat' do
      fill %w(a b c)

      array.concat(%w(x y z)).must_equal array
      array.to_a.must_equal %w(a b c x y z)
    end

    it 'clear' do
      fill %w(a b c d)

      array.clear.must_equal array
      array.to_a.must_equal []
    end

    it 'delete' do
      fill %w(a b a b a b)

      array.delete('b').must_equal 'b'
      array.to_a.must_equal %w(a a a)
      
      array.delete('c').must_be_nil
      array.to_a.must_equal %w(a a a)
    end

    it 'delete_at' do
      fill %w(a b c a b c a b c)

      array.delete_at(3).must_equal 'a'
      array.to_a.must_equal %w(a b c b c a b c)

      array.delete_at(-4).must_equal 'c'
      array.to_a.must_equal %w(a b c b a b c)

      array.delete_at(10).must_be_nil
      array.to_a.must_equal %w(a b c b a b c)
    end

    it 'delete_if' do
      fill %w(a b c a b c a b c)

      array.delete_if { |e| e == 'a' }.must_equal array
      array.to_a.must_equal %w(b c b c b c)
    end

  end

  describe 'Info' do

    %w(size count length).each do |method|
      it method do
        fill %w(a b c)
        array.send(method).must_equal 3
      end
    end

    it 'empty?' do
      array.empty?.must_equal true
      fill %w(a b c)
      array.empty?.must_equal false
    end

  end

  describe 'Transformations' do

    %w(to_a to_ary to_primitive).each do |method|
      it method do
        fill %w(a b c)
        array.send(method).must_equal %w(a b c)
      end
    end

    it 'join' do
      fill %w(a b c)

      array.join.must_equal 'abc'
      array.join('-').must_equal 'a-b-c'
    end

    it 'uniq' do
      fill %w(a1 a1 a2 a2 b1 b1 b2 b2)

      array.uniq.must_equal %w(a1 a2 b1 b2)
      array.uniq { |e| e[1] }.must_equal %w(a1 a2)
    end

    it 'reverse' do
      fill %w(a b c)
      array.reverse.must_equal %w(c b a)
    end

  end

  describe 'Enumerable' do

    it 'each' do
      fill %w(a b c)

      list = []
      array.each { |e| list << e }

      list.must_equal array.to_a
    end
    
    it 'each_index' do
      fill %w(a b c)

      list = []
      array.each_index { |i| list << i }

      list.must_equal [0,1,2]
    end

    it 'any?' do
      array.any?.must_equal false
      fill %w(a b c)
      array.any?.must_equal true
      array.any? { |e| e == 'a' }.must_equal true
      array.any? { |e| e == 'z' }.must_equal false
    end

    %w(detect find).each do |method|
      it method do
        fill %w(a1 b1 a2 b2)
        array.send(method) { |e| e.start_with? 'b' }.must_equal 'b1'
        array.send(method) { |e| e.start_with? 'x' }.must_be_nil
      end
    end

    %w(select find_all).each do |method|
      it method do
        fill %w(a1 b1 a2 b2)
        array.send(method) { |e| e.start_with? 'b' }.must_equal %w(b1 b2)
        array.send(method) { |e| e.start_with? 'x' }.must_equal []
      end
    end

    %w(map collect).each do |method|
      it method do
        fill %w(a1 b1 a2 b2)
        array.send(method) { |e| e[0] }.must_equal %w(a b a b)
      end
    end

    it 'sort' do
      fill %w(x3 a6 c4 y2 z1 b5)

      array.sort.must_equal %w(a6 b5 c4 x3 y2 z1)
      array.sort { |e1, e2| e1[1] <=> e2[1] }.must_equal %w(z1 y2 x3 c4 b5 a6)
    end

  end

  describe 'Symbols' do

    it '+' do
      fill %w(a b c)
      (array + %w(x y z)).must_equal %w(a b c x y z)
    end
    
    it '-' do
      fill %w(a b c)
      (array - %w(a z)).must_equal %w(b c)
    end

    it '&' do
      fill %w(a b c)
      (array & %w(b a z)).must_equal %w(a b)
    end

    it '|' do
      fill %w(a b c)
      (array | %w(b c d)).must_equal %w(a b c d)
    end

  end

  it 'Dump/Restore' do
    fill %w(a b c)
    
    dump = array.dump
    other = Restruct::StringArray.new
    other.restore dump

    other.key.wont_equal array.key
    other.to_a.must_equal %w(a b c)
  end

end