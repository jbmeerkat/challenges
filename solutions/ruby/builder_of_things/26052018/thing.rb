require 'active_support/core_ext/string'

class ArrayOfThings < Array
  def initialize(elements)
    super
    @elements = elements
  end

  def each(&block)
    if block_given?
      @elements.each do |element|
        element.instance_eval(&block)
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

class InterceptCall
  def initialize(&block)
    @on_call = block
  end

  def method_missing(method_name)
    @on_call.(method_name)
  end
end

class Thing
  attr_reader :name, :attributes, :_spoke_phrases

  def initialize(name = nil)
    @name = name
    self.class.send(:define_method, "#{name}?") { true }

    @attributes = {}
    @_spoke_phrases = []
  end

  def is_a
    InterceptCall.new do |name|
      attributes[name.to_s] = true
    end
  end

  def is_not_a
    InterceptCall.new do |name|
      attributes[name.to_s] = false
    end
  end

  def has(count)
    if count == 1
      InterceptCall.new do |name|
        name = name.to_s
        attributes[name] = Thing.new(name)
      end
    else
      InterceptCall.new do |name|
        name = name.to_s
        single_thing_name = name.singularize

        things = ArrayOfThings.new(
          Array.new(count) { Thing.new(single_thing_name) }
        )
        attributes[name] = things
      end
    end
  end
  alias_method :having, :has

  def is_the
    callback = lambda do |args|
      attributes[args.first.to_s] = args.last.to_s
      self
    end

    Spy.new(
      calls_expected: 2,
      callback: callback
    )
  end
  alias_method :being_the, :is_the
  alias_method :and_the, :is_the

  def can
    self
  end

  def speak(key = nil, &block)
    if block_given?
      configure_speaking(phrase: block, store_in: key)
    else
      output = instance_exec(key, &@speak)
      _spoke_phrases << output
      output
    end
  end

  def method_missing(method_name, *args)
    name = method_name.to_s.delete('?')

    attributes[name]
  end

  private

  def configure_speaking(phrase:, store_in:)
    @speak = phrase

    if store_in
      self.class.send(:define_method, store_in) { _spoke_phrases }
    end
  end
end
