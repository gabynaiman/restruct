require 'minitest_helper'

describe Restruct::Locker do

  let(:locker) { Restruct::Locker.new }

  it 'Flexible' do
    locker.wont_be :locked?

    locker.lock :process_1 do
      locker.must_be :locked?
      locker.locked_by.must_equal 'process_1'
      
      locker.lock(:process_1) { }
      locker.to_h.must_equal({"key"=>"process_1", "exclusive"=>"false", "nested"=>"1"})

      error = proc { locker.lock :process_2 }.must_raise Restruct::LockerError
      error.message.must_equal 'Lock process_2 (exclusive=false) fail. Alradey locked by process_1 (exclusive=false)'
    end

    locker.wont_be :locked?
  end

  it 'Strict' do
    locker.wont_be :locked?

    locker.lock! :process_1 do
      locker.must_be :locked?
      locker.locked_by.must_equal 'process_1'

      error = proc { locker.lock! :process_1 }.must_raise Restruct::LockerError
      error.message.must_equal 'Lock process_1 (exclusive=true) fail. Alradey locked by process_1 (exclusive=true)'

      error = proc { locker.lock :process_2 }.must_raise Restruct::LockerError
      error.message.must_equal 'Lock process_2 (exclusive=false) fail. Alradey locked by process_1 (exclusive=true)'
    end

    locker.wont_be :locked?
  end

  it 'Force unlock' do
    connection.call('HSET', locker.id, 'key', :process_1)

    locker.must_be :locked?
    locker.locked_by.must_equal 'process_1'

    locker.unlock!
    
    locker.wont_be :locked?
  end

  it 'Threads safe' do
    test_id = Restruct.generate_id[:test]

    threads = 10.times.map do |thread_number|
      Thread.new do
        10.times do |iteration|
          locker.lock :process_1 do
            connection.call 'RPUSH', test_id, "#{thread_number}-#{iteration}"
          end
        end
      end
    end

    threads.each(&:join)

    locker.wont_be :locked?

    expected_list = []
    10.times do |i|
      10.times do |j|
        expected_list << "#{i}-#{j}"
      end
    end

    list = connection.call('LRANGE', test_id, 0, -1)
    list.sort.must_equal expected_list
    list.wont_equal expected_list
  end

  if RUBY_ENGINE != 'jruby'
    it 'Multiples process' do
      test_id = Restruct.generate_id[:test]
      locker_id = locker.id

      pids = 10.times.map do |thread_number|
        Process.fork do
          connection = Restruct::Connection.new
          locker = Restruct::Locker.new id: locker_id, connection: connection
          10.times do |iteration|
            locker.lock :process_1 do
              connection.call 'RPUSH', test_id, "#{thread_number}-#{iteration}"
            end
          end
        end
      end

      Process.waitall

      locker.wont_be :locked?

      expected_list = []
      10.times do |i|
        10.times do |j|
          expected_list << "#{i}-#{j}"
        end
      end

      list = connection.call('LRANGE', test_id, 0, -1)
      list.sort.must_equal expected_list
      list.wont_equal expected_list
    end
  end

  it 'Return block result' do
    result = locker.lock :process_1 do
      'OK'  
    end

    result.must_equal 'OK'
  end
  
  it 'Unlock when raise error in block' do
    locker.wont_be :locked?

    proc do
      locker.lock :process_1 do
        raise RuntimeError, 'ERROR'
      end
    end.must_raise RuntimeError, 'ERROR'

    locker.wont_be :locked?
  end
 
end