local redis_key = ARGV[1]
local locker_key = ARGV[2]
local exclusive = ARGV[3]

if redis.call('EXISTS', redis_key ) == 1 then
  if exclusive == "true" then
    error("No se puede lockear exclusivo. Ya está lockeado")
  end
  if redis.call('HEXISTS', redis_key, 'exclusive' ) == 1 and redis.call('HGET', redis_key, 'exclusive') == 'true' then
    error("Ya está lockeado exclusivo")
  end
  if redis.call('HEXISTS', redis_key, 'key' ) == 1 then
    if redis.call('HGET', redis_key, 'key') ~= locker_key then
      error("Está lockeado por otro")
    end
  end
end

redis.call('HSET', redis_key, 'key', locker_key)
redis.call('HSET', redis_key, 'exclusive', exclusive)
redis.call("HINCRBY", redis_key, 'nested', 1)