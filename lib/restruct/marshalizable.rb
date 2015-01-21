module Restruct
  module Marshalizable
    
    def serialize(element)
      Marshal.dump element
    end
    
    def deserialize(element)
      Marshal.load element if element
    end

  end
end