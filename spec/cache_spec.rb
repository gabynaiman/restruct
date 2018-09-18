require 'minitest_helper'

[Restruct::Cache, Restruct::MarshalCache].each do |klass|

  describe klass do

    let(:sample_cache) { klass.new ttl: 500 }

    def fill(data)
      data.each do |k,v|
        connection.call 'SET', sample_cache.id[k], sample_cache.send(:serialize, v)
        connection.call 'EXPIRE', sample_cache.id[k], sample_cache.ttl
      end
    end

    describe 'Getters' do
      
      it '[]' do
        fill a: 'x', b: 'y'

        sample_cache[:a].must_equal 'x'
        sample_cache[:b].must_equal 'y'
        sample_cache[:c].must_be_nil
      end

      it 'fetch' do
        fill a: 'x', b: 'y'

        sample_cache.fetch(:a) { 'z' }.must_equal 'x'
        sample_cache.fetch(:b) { 'z' }.must_equal 'y'
        sample_cache.fetch(:c) { 'z' }.must_equal 'z'
      end

      it 'keys' do
        fill a: 'x', b: 'y', c: 'z'
        sample_cache.keys.must_equal %w(a b c)
      end

    end

    describe 'Setters' do
      
      it 'delete' do
        fill a: 'x', b: 'y'

        sample_cache.delete(:b).must_equal 'y'
        sample_cache.to_h.must_equal 'a' => 'x'
        
        sample_cache.delete(:c).must_be_nil
        sample_cache.to_h.must_equal 'a' => 'x'
      end
      
      it 'clear' do
        fill a: 'x', b: 'y'

        sample_cache.clear.must_equal sample_cache
        sample_cache.must_be_empty
      end

    end

    describe 'Info' do

      %w(size count length).each do |method|
        it method do
          fill a: 'x', b: 'y'
          sample_cache.send(method).must_equal 2
        end
      end
      
      it 'empty?' do
        sample_cache.must_be :empty?
        fill a: 'x', b: 'y'
        sample_cache.wont_be :empty?
      end

      %w(key? has_key?).each do |method|
        it method do
          fill a: 'x', b: 'y'

          assert sample_cache.send(method, :a)
          refute sample_cache.send(method, :c)
        end
      end

    end

    describe 'Transformations' do

      %w(to_h to_primitive).each do |method|
        it method do
          fill a: 'x', b: 'y'
          sample_cache.send(method).must_equal 'a' => 'x', 'b' => 'y'
        end
      end

    end

    describe 'Enumerable' do

      it 'included module' do
        assert Restruct::Hash.included_modules.include? Enumerable
      end

      it 'each' do
        fill a: 'x', b: 'y'

        hash = sample_cache.each_with_object({}) { |(k,v), h| h[k] = v }

        hash.must_equal sample_cache.to_h
      end

    end

    it 'Equality' do
      copy = klass.new id: sample_cache.id, ttl: sample_cache.ttl
      assert sample_cache == copy
      assert sample_cache.eql? copy
      refute sample_cache.equal? copy
    end

    it 'Dump/Restore' do
      fill a: 'x', b: 'y'
      
      dump = sample_cache.dump
      other = klass.new ttl: sample_cache.ttl
      other.restore dump

      other.id.wont_equal sample_cache.id
      other.to_primitive.must_equal sample_cache.to_primitive
    end

    it 'Batch' do
      fill a: 'x', b: 'y', c: 'z'

      sample_cache.connection.batch do
        sample_cache[:d] = 'w'
        sample_cache.delete :a
        sample_cache[:b] = 'x'
        
        sample_cache.to_h.must_equal 'a' => 'x', 'b' => 'y', 'c' => 'z'    
      end

      sample_cache.to_h.must_equal 'b' => 'x', 'c' => 'z', 'd' => 'w'
    end

  end

end