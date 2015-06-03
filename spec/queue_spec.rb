require 'minitest_helper'

[Restruct::Queue, Restruct::MarshalQueue].each do |klass|

  describe klass do

    it 'Push and pop' do
      queue = klass.new

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

  end
end