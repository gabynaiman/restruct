local locker_id = ARGV[1]
local lock_key  = ARGV[2]
local exclusive = ARGV[3]

if redis.call('EXISTS', locker_id) == 1 then
  local actual_lock_key = redis.call('HGET', locker_id, 'key')
  local actual_exclusive = redis.call('HGET', locker_id, 'exclusive')

  local error_message = "Lock " .. lock_key .. " (exclusive=" .. exclusive .. ") fail. Alradey locked by " .. actual_lock_key .. " (exclusive=" .. actual_exclusive .. ")"

  if exclusive == "true" or
     actual_exclusive == 'true'  or
     actual_lock_key ~= lock_key then
    
    error(error_message)
  end 
end

redis.call('HSET', locker_id, 'key', lock_key)
redis.call('HSET', locker_id, 'exclusive', exclusive)
redis.call("HINCRBY", locker_id, 'nested', 1)