module Restruct
  class Array < StringArray

    def [](index)
      element = super
      Marshal.load element
    end

    def push(element)
      super Marshal.dump(element)
    end

  end
end