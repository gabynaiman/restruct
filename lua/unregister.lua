local redis_key = ARGV[1]
local locker_key = ARGV[2]
local exclusive = ARGV[3]

if redis.call('EXISTS', redis_key ) == 1 then
  if redis.call('HEXISTS', redis_key, 'exclusive' ) == 1 then
    local is_exclusive = redis.call('HGET', redis_key, 'exclusive')
    if exclusive == "true" and is_exclusive == 'false' then
      error("No se puede deslockear exclusivo. Está lockeado no exclusivo")
    end
    if exclusive == "false" and is_exclusive == 'true' then
      error("No se puede deslockear no exclusivo. Está lockeado exclusivo")
    end
  end
  if redis.call('HEXISTS', redis_key, 'key' ) == 1 then
    if redis.call('HGET', redis_key, 'key') ~= locker_key then
      error("Está lockeado por otro")
    end
  end
end

redis.call("HINCRBY", redis_key, 'nested', -1)
if redis.call('HGET', redis_key, 'nested') == '0' then
  redis.call('DEL', redis_key)
end
