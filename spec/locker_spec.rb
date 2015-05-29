require 'minitest_helper'

describe Restruct::Locker do

  let(:locker) { Restruct::Locker.new }

  it 'Flexible' do
    locker.wont_be :locked?

    locker.lock :process_1 do
      locker.must_be :locked?
      locker.locked_by.must_equal 'process_1'
      
      locker.lock(:process_1) { }

      error = proc { locker.lock :process_2 }.must_raise Restruct::Locker::Error
      #error.message.must_equal 'test already locked by process_1'
    end

    locker.wont_be :locked?
  end

  it 'Strict' do
    locker.wont_be :locked?

    locker.lock! :process_1 do
      locker.must_be :locked?
      locker.locked_by.must_equal 'process_1'

      error = proc { locker.lock! :process_1 }.must_raise Restruct::Locker::Error
      #error.message.must_equal 'test already locked by process_1'

      error = proc { locker.lock :process_2 }.must_raise Restruct::Locker::Error
      #error.message.must_equal 'test already locked by process_1'
    end

    locker.wont_be :locked?
  end

  it 'Force unlock' do
    redis.call('HSET', locker.id, 'key', :process_1)

    locker.must_be :locked?
    locker.locked_by.must_equal 'process_1'

    locker.unlock!
    
    locker.wont_be :locked?
  end

  it 'Multiple update sharing locker' do
    test_id = Restruct.generate_id[:test_counter]

    threads = 10.times.map do |i|
      Thread.new do
        10.times do
          locker.lock :process_1 do
            # TODO: grabar en una lista Nro_thread - iteracion (1-1,1-2,2-1)
            redis.call("HINCRBY", test_id, 'counter', 1)
          end
        end
      end
    end

    threads.each(&:join)

    locker.wont_be :locked?
    redis.call('HGET', test_id, 'counter').must_equal '100'
  end
  
end