module Wiretap

  # a Wiretap::Signal is much like a Promise in functional programming.  A
  # Signal is triggered with a new value, or it is completed, or canceled with
  # an error event.
  class Signal

    def initialize
    end

    def next(value)
    end

    def complete
    end

    def error
    end

  end

end
