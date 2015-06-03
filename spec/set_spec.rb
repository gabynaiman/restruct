require 'minitest_helper'

[Restruct::Set, Restruct::MarshalSet].each do |klass|

  describe klass do

    let(:set) { klass.new }

    def fill(elements)
      connection.call 'SADD', set.id, *(elements.map { |e| set.send(:serialize, e) })
    end

    describe 'Setters' do
      
      %w(add <<).each do |method|
        it method do
          fill %w(a b)
          
          set.send(method, 'b').must_equal set
          set.to_set.must_equal Set.new %w(a b)

          set.send(method, 'c').must_equal set
          set.to_set.must_equal Set.new %w(a b c)
        end
      end
      
      it 'add?' do
        fill %w(a b)
        
        set.add?('b').must_be_nil
        set.to_set.must_equal Set.new %w(a b)

        set.add?('c').must_equal set
        set.to_set.must_equal Set.new %w(a b c)
      end

      it 'merge' do
        fill %w(a b)

        set.merge(%w(b c d)).must_equal set
        set.to_set.must_equal Set.new %w(a b c d)
      end
      
      it 'delete' do
        fill %w(a b c d)

        set.delete('x').must_equal set
        set.to_set.must_equal Set.new %w(a b c d)

        set.delete('b').must_equal set
        set.to_set.must_equal Set.new %w(a c d)
      end
      
      it 'delete?' do
        fill %w(a b c d)

        set.delete?('x').must_be_nil
        set.to_set.must_equal Set.new %w(a b c d)

        set.delete?('b').must_equal set
        set.to_set.must_equal Set.new %w(a c d)
      end
      
      it 'subtract' do
        fill %w(a b c d)

        set.subtract(%w(b c x)).must_equal set
        set.to_set.must_equal Set.new %w(a d)
      end

      it 'delete_if' do
        fill %w(a b c)

        set.delete_if { |e| e == 'a' }.must_equal set
        set.to_set.must_equal Set.new(%w(b c))
      end

      %w(keep_if select!).each do |method|
        it method do
          fill %w(a b c)

          set.send(method) { |e| e == 'a' }.must_equal set
          set.to_set.must_equal Set.new(%w(a))
        end
      end

      it 'clear' do
        fill %w(a b c d)

        set.clear.must_equal set
        set.must_be_empty
      end
      
    end

    describe 'Info' do

      %w(size count length).each do |method|
        it method do
          fill %w(a b c)
          set.send(method).must_equal 3
        end
      end

      it 'empty?' do
        set.must_be :empty?
        fill %w(a b c)
        set.wont_be :empty?
      end

      it 'include?' do
        fill %w(a b c)

        assert set.include? 'a'
        refute set.include? 'z'
      end

    end

    describe 'Transformations' do

      it 'to_a' do
        fill %w(a b c)
        set.to_a.sort.must_equal %w(a b c)
      end

      %w(to_set to_primitive).each do |method|
        it method do
          fill %w(a b c)
          set.send(method).must_equal Set.new(%w(a b c))
        end
      end

    end

    describe 'Enumerable' do

      it 'included module' do
        assert klass.included_modules.include? Enumerable
      end

      it 'each' do
        fill %w(a b c)

        members = Set.new
        set.each { |e| members << e }

        members.must_equal set.to_set
      end

    end

    describe 'Sets' do
      
      %w(union | +).each do |method|
        it method do
          fill %w(a b c)
          set.send(method, %w(a x y)).must_equal Set.new(%w(a b c x y))
        end
      end

      %w(intersection &).each do |method|
        it method do
          fill %w(a b c)
          set.send(method, %w(b a z)).must_equal Set.new(%w(a b))
        end
      end
      
      %w(difference -).each do |method|
        it method do
          fill %w(a b c)
          set.send(method, %w(a z)).must_equal Set.new(%w(b c))
        end
      end

      %w(proper_subset? <).each do |method|
        it method do
          fill %w(a b)
          
          assert set.send(method, Set.new(%w(a b c)))
          refute set.send(method, Set.new(%w(a b)))
          refute set.send(method, Set.new(%w(a x)))
        end
      end

      %w(subset? <=).each do |method|
        it method do
          fill %w(a b)
          
          assert set.send(method, Set.new(%w(a b c)))
          assert set.send(method, Set.new(%w(a b)))
          refute set.send(method, Set.new(%w(a x)))
        end
      end

      %w(proper_superset? >).each do |method|
        it method do
          fill %w(a b c)
          
          assert set.send(method, Set.new(%w(a b)))
          refute set.send(method, Set.new(%w(a b c)))
          refute set.send(method, Set.new(%w(a x)))
        end
      end

      %w(superset? >=).each do |method|
        it method do
          fill %w(a b c)
          
          assert set.send(method, Set.new(%w(a b)))
          assert set.send(method, Set.new(%w(a b c)))
          refute set.send(method, Set.new(%w(a x)))
        end
      end
      
      it 'intersect?' do
        fill %w(a b c)

        assert set.intersect? Set.new(%w(a x y))
        refute set.intersect? Set.new(%w(x y z))
      end
      
      it 'disjoint?' do
        fill %w(a b c)

        refute set.disjoint? Set.new(%w(a x y))
        assert set.disjoint? Set.new(%w(x y z))
      end

      it '^' do
        fill %w(a b c)
        (set ^ %w(a x y)).must_equal Set.new(%w(b c x y))
      end

    end

    it 'Equality' do
      copy = klass.new id: set.id
      assert set == copy
      assert set.eql? copy
      refute set.equal? copy
    end

    it 'Dump/Restore' do
      fill %w(a b c)
      
      dump = set.dump
      other = klass.new
      other.restore dump

      other.id.wont_equal set.id
      other.to_primitive.must_equal set.to_primitive
    end

  end

end