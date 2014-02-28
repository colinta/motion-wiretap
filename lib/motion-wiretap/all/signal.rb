module MotionWiretap

  # a Wiretap::Signal is much like a Promise in functional programming.  A
  # Signal is triggered with a new value, or it is completed, or canceled with
  # an error event.
  class Signal < Wiretap
    attr :value

    def initialize(value=nil)
      super()
      @value = value
      trigger_changed(@value)
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

  end

end
