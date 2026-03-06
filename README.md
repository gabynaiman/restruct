# Restruct

[![Gem Version](https://badge.fury.io/rb/restruct.svg)](https://rubygems.org/gems/restruct)
[![Coverage Status](https://coveralls.io/repos/gabynaiman/restruct/badge.svg?branch=master)](https://coveralls.io/r/gabynaiman/restruct?branch=master)

Ruby data structures backed by Redis. Provides persistent, distributed versions of common collections that can be shared across processes and servers.

### Structures

- **Array** - Ordered collection (Redis list)
- **Set** - Unique unordered collection (Redis set)
- **Hash** - Key-value store (Redis hash)
- **NestedHash** - Hash where each value is a nested Structure instance
- **Queue** - FIFO queue (Redis list)
- **Cache** - Key-value store with optional TTL
- **Locker** - Distributed lock with shared and exclusive modes

All structures have a Marshal variant (`MarshalArray`, `MarshalSet`, etc.) for storing complex Ruby objects instead of plain strings.

## Installation

Add this line to your application's Gemfile:

    gem 'restruct'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install restruct

## Usage

### Configuration

```ruby
Restruct.configure do |config|
  # Default connection (localhost:6379)
  config.connection = Restruct::Connection.simple

  # Custom Redis URL
  config.connection = Restruct::Connection.simple('redis://localhost:6379')

  # With Redis Sentinels
  config.connection = Restruct::Connection.with_sentinels(master_name, sentinels)

  # Custom ID separator (default: ':')
  config.id_separator = ':'

  # Custom ID generator (default: restruct:<uuid>)
  config.id_generator = -> { Restruct::Id.new(:my_app)[SecureRandom.uuid] }
end
```

Each option can also be set individually:

```ruby
Restruct.connection = Restruct::Connection.simple('redis://localhost:6379')
Restruct.id_separator = ':'
Restruct.id_generator = -> { Restruct::Id.new(:my_app)[SecureRandom.uuid] }
```

### Array

Ordered collection backed by a Redis list.

```ruby
array = Restruct::Array.new

array.push 'a', 'b', 'c'
array << 'd'
array.insert 2, 'x'

array[0]        # => 'a'
array[1..3]     # => ['b', 'x', 'c']
array[-1]       # => 'd'
array.first     # => 'a'
array.last      # => 'd'
array.size      # => 5
array.to_a      # => ['a', 'b', 'x', 'c', 'd']

array.pop       # => 'd'
array.shift     # => 'a'
array.delete 'x'
array.include? 'b' # => true
```

### Set

Unordered unique collection backed by a Redis set.

```ruby
set = Restruct::Set.new

set.add 'a'
set << 'b'
set.merge %w(c d)

set.include? 'a' # => true
set.size          # => 4

set.delete 'b'
set.subtract %w(c d)

# Set operations with other Restruct::Set or Ruby Set
other = Set.new(%w(b c d))
set.union other        # | +
set.intersection other # &
set.difference other   # -
set.subset? other      # <=
set.superset? other    # >=
```

### Hash

Key-value store backed by a Redis hash.

```ruby
hash = Restruct::Hash.new

hash['name'] = 'Alice'
hash.update 'age' => '30', 'city' => 'NYC'

hash['name']            # => 'Alice'
hash.fetch 'age', '0'   # => '30'
hash.keys               # => ['name', 'age', 'city']
hash.values             # => ['Alice', '30', 'NYC']
hash.key? 'name'        # => true
hash.size               # => 3
hash.to_h               # => {'name'=>'Alice', 'age'=>'30', 'city'=>'NYC'}

hash.delete 'city'      # => 'NYC'
hash.delete_if { |k, v| k == 'age' }
```

### NestedHash

Factory for creating hash-like structures where each value is an instance of a given Structure type.

```ruby
# Define a custom structure
class Counter < Restruct::Structure
  def current
    (connection.call('GET', id) || 0).to_i
  end

  def incr
    connection.call 'SET', id, current + 1
    self
  end

  alias_method :to_primitive, :current
end

# Create a NestedHash type
CounterHash = Restruct::NestedHash.new(Counter)

counters = CounterHash.new
counters[:page_views].incr
counters[:clicks].incr.incr

counters[:clicks].current  # => 2
counters.keys              # => ['page_views', 'clicks']
counters.to_h              # => {'page_views' => 1, 'clicks' => 2}

counters.delete :page_views
```

### Queue

FIFO queue backed by a Redis list.

```ruby
queue = Restruct::Queue.new

queue.push 'task_1'
queue.push 'task_2'

queue.size   # => 2
queue.pop    # => 'task_1'
queue.pop    # => 'task_2'
queue.pop    # => nil
```

### Cache

Key-value cache with optional TTL (time-to-live).

```ruby
cache = Restruct::Cache.new

cache['token'] = 'abc123'
cache['token']       # => 'abc123'
cache.key? 'token'   # => true
cache.keys           # => ['token']
cache.to_h           # => {'token' => 'abc123'}

cache.delete 'token' # => 'abc123'

# With TTL (in seconds)
cache = Restruct::Cache.new(ttl: 3600)
cache['session'] = 'data'  # Expires in 1 hour

# Fetch with fallback block
cache.fetch('key') { |k| compute_value(k) }
```

### Locker

Distributed lock with shared (flexible) and exclusive modes.

```ruby
locker = Restruct::Locker.new

# Shared lock (allows nested locks with the same key)
locker.lock :process_1 do
  # Critical section
  locker.locked?    # => true
  locker.locked_by  # => 'process_1'
end

# Exclusive lock (no other locks allowed)
locker.lock! :process_1 do
  # Exclusive critical section
end

# Lock is automatically released on errors
locker.locked?  # => false

# Force unlock
locker.unlock!
```

### Marshal Variants

All structures have a Marshal variant that stores complex Ruby objects using `Marshal.dump`/`Marshal.load`, instead of plain strings.

```ruby
array = Restruct::MarshalArray.new
array.push({name: 'Alice', age: 30})
array[0]  # => {:name=>'Alice', :age=>30}

hash = Restruct::MarshalHash.new
hash['user'] = {id: 1, tags: ['admin']}
hash['user'] # => {:id=>1, :tags=>['admin']}
```

Available classes: `MarshalArray`, `MarshalSet`, `MarshalHash`, `MarshalQueue`, `MarshalCache`.

### Common Features

All structures support:

```ruby
# Custom ID and connection
array = Restruct::Array.new(id: 'my:key', connection: my_connection)

# Existence and cleanup
array.exists?  # => true
array.destroy  # Deletes from Redis

# Dump and restore
dump = array.dump
other = Restruct::Array.new
other.restore dump

# Batch operations (atomic via Redis transaction)
array.connection.batch do
  array.push 'a'
  array.push 'b'
  array[0] = 'x'
end
```

## Contributing

1. Fork it ( https://github.com/gabynaiman/restruct/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
