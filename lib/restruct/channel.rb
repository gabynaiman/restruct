module Restruct
  class Channel < Structure

    def publish(message)
      connection.call 'PUBLISH', id, serialize(message)
    end

    def subscribe
      subscriber = connection.clone
      subscriber.call 'SUBSCRIBE', id
      loop do
        yield deserialize(subscriber.read.last)
      end
    rescue => ex
      raise ex
    ensure
      subscriber.call 'UNSUBSCRIBE', id
    end

    private

    def serialize(string)
      string
    end

    def deserialize(string)
      string
    end

  end
end