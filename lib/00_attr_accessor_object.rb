class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      setter = "#{name}=".to_sym

      define_method(name) { instance_variable_get("@#{name}") }
      define_method(setter) { |value| instance_variable_set("@#{name}", value) }
    end
  end
end
