module MotionWiretap

  # a Wiretap::Signal is much like a Promise in functional programming.  A
  # Signal is triggered with a new value, or it is completed, or canceled with
  # an error event.
  class Signal < Wiretap

    # The SINGLETON value does not trigger a 'change' event. It is for internal
    # use only.
    def initialize(value=SINGLETON, &block)
      super(&block)
      @value = value
    end

    def value
      if @value == SINGLETON
        nil
      else
        @value
      end
    end

    # If you pass multiple values to this method, the 'value' will be the array
    # of all the values, but they will be passed on to 'trigger_changed' using
    # the splat operator, and so will be passed to listener blocks as individual
    # arguments.
    #
    # Example:
    #     signal = Signal.new
    #     signal.listen do |a, b|
    #       @added = a + b
    #     end
    #     signal.next(1, 5)    # works great, @added will be 6
    #     signal.next([1, 5])  # this works, too, because of how args are assigned to blocks in ruby
    #     signal.next(1)  # a will be 1 and b will be nil (error!)
    def next(value, *values)
      if values.length > 0
        raise "don't do that please" if values.include? SINGLETON
        value = [value].concat values
        @value = value
        trigger_changed(*value)
      else
        raise "don't do that please" if value == SINGLETON
        @value = value
        trigger_changed(@value)
      end
    end

    def complete
      trigger_completed
    end

    def error(error=SINGLETON)
      trigger_error(error)
    end

    # The Signal class always sends an initial value
    def listen(wiretap=nil, &block)
      super
      unless @value == SINGLETON
        trigger_changed(@value)
      end
      return self
    end

  end

end
