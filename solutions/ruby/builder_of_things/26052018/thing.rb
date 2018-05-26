require "active_support/core_ext/string"

class Thing
  attr_reader :name, :context, :parent

  def initialize(name = nil, context: nil, parent: nil)
     @name = name
     @context = context
     @parent = parent
     @values = {}
  end

  def method_missing(name, *args)
    case name
    when :is_a
      Thing.new(context: true, parent: self)
    when :is_not_a
      Thing.new(context: false, parent: self)
    when :has
      things = args[0].times.map { Thing.new() }
      Thing.new(context: things, parent: self)
    else
      if name.to_s.end_with?('?')
        get_value(name)
      else
        if parent
          if context.is_a?(Array)
            context.each { |t| t.name = name }
          end
          parent.set_value(name, context)
        else
          get_value(name)
        end
      end
    end
  end

  def name=(new_name)
    @name = new_name.to_s.singularize
    self.class.send(:define_method, "#{name}?") { true }
  end

  def set_value(name, context)
    key = name.to_s
    @values[key] = context
  end

  def get_value(name)
    key = name.to_s.delete('?')
    @values[key]
  end
end
