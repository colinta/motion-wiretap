module MotionWiretap

  # a Wiretap::Signal is much like a Promise in functional programming.  A
  # Signal is triggered with a new value, or it is completed, or canceled with
  # an error event.
  class Signal < Wiretap
    attr :value

    def initialize(value=nil, &block)
      @value = value
      super(&block)
    end

    def next(value)
      @value = value
      trigger_changed(@value)
    end

    def complete
      trigger_completed
    end

    def error(error)
      trigger_error(error)
    end

    # The Signal class always sends an initial value
    def listen(wiretap=nil, &block)
      super
      trigger_changed(@value)
      return self
    end

  end

end
