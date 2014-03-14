module MotionWiretap

  # a Wiretap::Signal is much like a Promise in functional programming.  A
  # Signal is triggered with a new value, or it is completed, or canceled with
  # an error event.
  class Signal < Wiretap

    # The SINGLETON value does not trigger a 'change' event. It is for internal
    # use only.
    def initialize(value=SINGLETON, &block)
      @value = value
      super(&block)
    end

    def value
      if @value == SINGLETON
        nil
      else
        @value
      end
    end

    def next(value)
      raise "don't do that please" if value == SINGLETON
      @value = value
      trigger_changed(@value)
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
