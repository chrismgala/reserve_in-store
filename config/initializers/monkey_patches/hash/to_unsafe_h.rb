unless Hash.method_defined? :to_unsafe_h
  class Hash

    def to_unsafe_h
      to_h
    end
  end
end
