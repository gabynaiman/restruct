module Restruct
  module Marshalizable
    
    def serialize(element)
      Marshal.dump element
    end
    
    def deserialize(element)
      Marshal.load element unless element.nil?
    end

  end
end