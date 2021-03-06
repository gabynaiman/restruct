require 'minitest_helper'

[Restruct::Hash, Restruct::MarshalHash].each do |klass|

  describe klass do

    let(:sample_hash) { klass.new }

    def fill(data)
      data.each { |k,v| data[k] = sample_hash.send(:serialize, v) }
      connection.call 'HMSET', sample_hash.id, *data.flatten
    end

    describe 'Getters' do
      
      it '[]' do
        fill a: 'x', b: 'y'

        sample_hash[:a].must_equal 'x'
        sample_hash[:b].must_equal 'y'
        sample_hash[:c].must_be_nil
      end

      it 'fetch' do
        fill a: 'x', b: 'y'

        sample_hash.fetch(:a).must_equal 'x'
        sample_hash.fetch(:b).must_equal 'y'
        sample_hash.fetch(:c, 'z').must_equal 'z'
        sample_hash.fetch(:c) { |k| k.to_s }.must_equal 'c'
        
        error = proc { sample_hash.fetch(:c) }.must_raise KeyError
        error.message.must_equal 'key not found: c'
      end

      it 'key' do
        fill a: 'x', b: 'y', c: 'y'

        sample_hash.key('x').must_equal 'a'
        sample_hash.key('y').must_equal 'b'
        sample_hash.key('z').must_be_nil
      end

      it 'keys' do
        fill a: 'x', b: 'y', c: 'z'
        sample_hash.keys.must_equal %w(a b c)
      end

      it 'values' do
        fill a: 'x', b: 'y', c: 'z'
        sample_hash.values.must_equal %w(x y z)
      end

      it 'values_at' do
        fill a: 'x', b: 'y', c: 'z'
        sample_hash.values_at(:a, :f, :b, :g, :c).must_equal ['x', nil, 'y', nil, 'z']
      end

    end

    describe 'Setters' do
      
      %w([]= store).each do |method|
        it method do
          fill a: 'x', b: 'y'

          sample_hash.send(method, :a, 'a').must_equal 'a'
          sample_hash.to_h.must_equal 'a' => 'a', 'b' => 'y'

          sample_hash.send(method, :c, 'z').must_equal 'z'
          sample_hash.to_h.must_equal 'a' => 'a', 'b' => 'y', 'c' => 'z'
        end
      end

      %w(update merge!).each do |method|
        it method do
          fill a: 'x', b: 'y'

          sample_hash.send(method, a: 'a', c: 'z').must_equal sample_hash
          sample_hash.to_h.must_equal 'a' => 'a', 'b' => 'y', 'c' => 'z'
        end
      end
      
      it 'delete' do
        fill a: 'x', b: 'y'

        sample_hash.delete(:b).must_equal 'y'
        sample_hash.to_h.must_equal 'a' => 'x'
        
        sample_hash.delete(:c).must_be_nil
        sample_hash.to_h.must_equal 'a' => 'x'
      end
      
      it 'delete_if' do
        fill a: 'x', b: 'y'

        sample_hash.delete_if { |k,v| v == 'x' }.must_equal sample_hash
        sample_hash.to_h.must_equal 'b' => 'y'
      end

      %w(keep_if select!).each do |method|
        it method do
          fill a: 'x', b: 'y'

          sample_hash.send(method) { |k,v| v == 'x' }.must_equal sample_hash
          sample_hash.to_h.must_equal 'a' => 'x'
        end
      end
      
      it 'clear' do
        fill a: 'x', b: 'y'

        sample_hash.clear.must_equal sample_hash
        sample_hash.must_be_empty
      end

    end

    describe 'Info' do

      %w(size count length).each do |method|
        it method do
          fill a: 'x', b: 'y'
          sample_hash.send(method).must_equal 2
        end
      end
      
      it 'empty?' do
        sample_hash.must_be :empty?
        fill a: 'x', b: 'y'
        sample_hash.wont_be :empty?
      end

      %w(key? has_key?).each do |method|
        it method do
          fill a: 'x', b: 'y'

          assert sample_hash.send(method, :a)
          refute sample_hash.send(method, :c)
        end
      end
      
      %w(value? has_value?).each do |method|
        it method do
          fill a: 'x', b: 'y'

          assert sample_hash.send(method, 'x')
          refute sample_hash.send(method, 'z')
        end
      end

    end

    describe 'Transformations' do

      %w(to_h to_primitive).each do |method|
        it method do
          fill a: 'x', b: 'y'
          sample_hash.send(method).must_equal 'a' => 'x', 'b' => 'y'
        end
      end

      it 'merge' do
        fill a: 'x', b: 'y'
        sample_hash.merge('c' => 'z', 'a' => 'a').must_equal 'a' => 'a', 'b' => 'y', 'c' => 'z'
      end
      
      it 'flatten' do
        fill a: 'x', b: 'y'
        sample_hash.flatten.must_equal %w(a x b y)
      end

      it 'invert' do
        fill a: 'x', b: 'y'
        sample_hash.invert.must_equal 'x' => 'a', 'y' => 'b'
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
          sample_hash.send(method) do |k,v|
            keys << k
            values << v
          end

          keys.must_equal sample_hash.keys
          values.must_equal sample_hash.values
        end
      end
      
      it 'each_key' do
        fill a: 'x', b: 'y'

        keys = []
        sample_hash.each_key { |k| keys << k }

        keys.must_equal sample_hash.keys
      end
      
      it 'each_value' do
        fill a: 'x', b: 'y'

        values = []
        sample_hash.each_value { |v| values << v }

        values.must_equal sample_hash.values
      end

    end

    it 'Equality' do
      copy = klass.new id: sample_hash.id
      assert sample_hash == copy
      assert sample_hash.eql? copy
      refute sample_hash.equal? copy
    end

    it 'Dump/Restore' do
      fill a: 'x', b: 'y'
      
      dump = sample_hash.dump
      other = klass.new
      other.restore dump

      other.id.wont_equal sample_hash.id
      other.to_primitive.must_equal sample_hash.to_primitive
    end

    it 'Batch' do
      fill a: 'x', b: 'y', c: 'z'

      sample_hash.connection.batch do
        sample_hash[:d] = 'w'
        sample_hash.delete :a
        sample_hash.merge! b: 'x', e: 'v'
        
        sample_hash.to_h.must_equal 'a' => 'x', 'b' => 'y', 'c' => 'z'    
      end

      sample_hash.to_h.must_equal 'b' => 'x', 'c' => 'z', 'd' => 'w', 'e' => 'v'
    end

  end

end