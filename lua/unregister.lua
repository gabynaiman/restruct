local locker_id = ARGV[1]

if redis.call('EXISTS', locker_id) == 0 then
  error("Unregister Error. Dont exist key " .. locker_id)
else
  redis.call("HINCRBY", locker_id, 'nested', -1)
  if redis.call('HGET', locker_id, 'nested') == '0' then
    redis.call('DEL', locker_id)
  end
end