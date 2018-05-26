require 'active_support/core_ext/string'

class ArrayOfThings < Array
  def initialize(elements)
    super
    @elements = elements
  end

  def each(&block)
    if block_given?
      @elements.each do |element|
        element.instance_eval &block
      end

      @elements
    else
      super
    end
  end
end

class Spy
  def initialize(calls_expected:, callback:)
    @calls_expected = calls_expected
    @called_times = 0
    @methods_called = []
    @callback = callback
  end

  def method_missing(method_name)
    @methods_called << method_name
    @called_times += 1

    if @called_times >= @calls_expected
      @callback.call @methods_called
    else
      self
    end
  end
end

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
    when :has, :having
      number = args.first
      if number == 1
        thing = Thing.new
        Thing.new(context: thing, parent: self)
      else
        things = ArrayOfThings.new(number.times.map { Thing.new() })
        Thing.new(context: things, parent: self)
      end
    when :is_the
      Spy.new(
        calls_expected: 2,
        callback: ->(args) { @values[args.first.to_s] = args.last.to_s }
      )
    else
      if name.to_s.end_with?('?')
        get_value(name)
      else
        if parent
          Array(context).
            select { |t| t.is_a?(Thing) }.
            each { |t| t.name = name }

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
