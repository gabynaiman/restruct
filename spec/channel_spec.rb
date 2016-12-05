require 'minitest_helper'

[Restruct::Channel, Restruct::MarshalChannel].each do |klass|

  describe klass do

    let(:channel) { klass.new }

    it 'Subscribe and publish' do
      messages = []

      Thread.new do
        channel.subscribe do |message|
          messages << message
        end
      end
      sleep 0.01 # Wait for establish connection

      3.times do |i|
        channel.publish "Message #{i}"
      end

      Timeout.timeout(3) do
        while messages.count < 3; 
          sleep 0.0001 # Wait for subscriptions
        end
      end

      messages.must_equal 3.times.map { |i| "Message #{i}" }
    end

  end
end