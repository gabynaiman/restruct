require 'minitest_helper'

describe Restruct::Connection do

  describe 'Success' do
    it 'call' do
      connection.call('HSET', 'test_id', 'key', 'test_key')
      connection.call('HGET', 'test_id', 'key').must_equal 'test_key'
    end

    it 'script' do
      script = %Q{
        local id = ARGV[1]
        local key = ARGV[2]
        local value = ARGV[3]
        redis.call('HSET', id, key, value)
        return redis.call('HGET', id, key)
      }
      connection.script(script, 0, 'test_id', 'key', 'test_key').must_equal 'test_key'
    end

    it 'reload script when remove from the redis cache' do
      script = %Q{
        local id = ARGV[1]
        return id
      }
      connection.script(script, 0, 'test').must_equal 'test'
      connection.call 'SCRIPT', 'FLUSH'
      connection.script(script, 0, 'test').must_equal 'test'
    end

  end

  describe 'Errors' do

    it 'ArgumentError' do
      proc { connection.call }.must_raise ArgumentError
    end

    it 'NoScriptError' do
      proc { connection.call 'EVALSHA', 'invalid sha', 0 }.must_raise Restruct::NoScriptError
    end

    it 'Invalid Script' do
      proc { connection.script 'xyz', 0 }.must_raise Restruct::ConnectionError
    end

    it 'RuntimeScriptError' do
      proc { connection.script 'return x', 0 }.must_raise Restruct::ConnectionError
    end

  end

end