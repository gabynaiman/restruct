module Restruct
  class MarshalArray < Array

    private

    def serialize(element)
      Marshal.dump element
    end
    
    def deserialize(element)
      Marshal.load element if element
    end

  end
end