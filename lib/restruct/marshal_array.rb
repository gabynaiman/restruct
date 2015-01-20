module Restruct
  class MarshalArray < Array

    def [](index)
      element = super
      Marshal.load element
    end

    def push(element)
      super Marshal.dump(element)
    end

  end
end