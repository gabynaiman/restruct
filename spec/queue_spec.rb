require 'minitest_helper'

[Restruct::Queue, Restruct::MarshalQueue].each do |klass|

  describe klass do

    let(:queue) { klass.new }

    it 'Push and pop' do
      queue.must_be :empty?

      queue.push 'test_1'
      queue.push 'test_2'

      queue.wont_be :empty?
      queue.size.must_equal 2
      queue.to_a.must_equal ['test_1', 'test_2']

      queue.pop.must_equal 'test_1'
      queue.wont_be :empty?
      queue.size.must_equal 1
      queue.to_a.must_equal ['test_2']

      queue.pop.must_equal 'test_2'
      queue.must_be :empty?
    end

    it 'Batch' do
      %w(a b c).each {|e| queue.push e}

      queue.connection.batch do
        queue.push 'd'
        queue.pop
        queue.to_a.must_equal %w(a b c)
      end

      queue.to_a.must_equal %w(b c d)
    end

  end
end