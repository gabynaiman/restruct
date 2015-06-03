local redis_key = ARGV[1]

redis.call("HINCRBY", redis_key, 'nested', -1)
if redis.call('HGET', redis_key, 'nested') == '0' then
  redis.call('DEL', redis_key)
end
