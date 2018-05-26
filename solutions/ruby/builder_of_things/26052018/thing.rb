class Thing
  attr_reader :name, :context, :parent
  def initialize(name, context = nil, parent = nil)
     @name = name
     @context = context
     @parent = parent
     @values = {}
  end

  def method_missing(name, *args)
    case name
    when :is_a
      create_new_thing_with_value(true)
    when :is_not_a
      create_new_thing_with_value(false)
    else
      if name.to_s.end_with?('?')
        read_value(name.to_s.delete('?'))
      else
        send_value_to_parent(parent, name.to_s, context)
      end
    end
  end

  def create_new_thing_with_value(context)
    Thing.new(name, context, self)
  end

  def send_value_to_parent(parent, name, context)
    parent.set_value(name, context)
  end

  def set_value(name, context)
    @values[name] = context
  end

  def read_value(name)
    @values[name]
  end
end
