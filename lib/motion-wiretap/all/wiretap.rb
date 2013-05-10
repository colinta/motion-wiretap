module MotionWiretap

  class Wiretap

    def initialize(&block)
      @initial = nil
      @initial_is_set = false

      @listener_handlers = []
      @completion_handlers = []
      @error_handlers = []

      listen &block if block
    end

    ##|
    ##|  Wiretap events
    ##|

    # called when the value changes
    def listen(&block)
      raise "Block is expected in #{self.class.name}##{__method__}" unless block
      @listener_handlers << block
      self
    end

    def trigger_changed(*values)
      @listener_handlers.each do |block|
        block.call(*values)
      end
    end

    # called when no more values are expected
    def and_then(&block)
      raise "Block is expected in #{self.class.name}##{__method__}" unless block
      @completion_handlers << block
      self
    end

    def trigger_completed
      @completion_handlers.each do |block|
        block.call
      end
    end

    # called when an error occurs, and no more values are expected
    def on_error(&block)
      raise "Block is expected in #{self.class.name}##{__method__}" unless block
      @error_handlers << block
      self
    end

    def trigger_error(error)
      @error_handlers.each do |block|
        block.call(error)
      end
    end

    ##|
    ##|  Wiretap Predicates
    ##|

    # Returns a Wiretap that will only be called if the &condition block returns true
    def filter(&condition)
    end

  end

  class WiretapKvo < Wiretap
    attr :target
    attr :property
    attr :value

    def initialize(target, property, &block)
      @target = WeakRef.new(target)
      @property = property
      @value = nil
      super(&block)

      @target.addObserver(self,
        forKeyPath: property.to_s,
        options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial,
        context: nil
        )
    end

    def dealloc
      @target.removeObserver(self,
        forKeyPath: @property.to_s
        )
      super
    end

    def observeValueForKeyPath(path, ofObject: target, change: change, context: context)
      @value = change[NSKeyValueChangeNewKey]
      if @initial_is_set
        trigger_changed(@value)
      else
        @initial = @value
        @initial_is_set = true
      end
    end

  end

  class WiretapArray < Wiretap
    attr :targets

    def initialize(targets, &block)
      @targets = targets  # this should be an array of Wiretap objects
      @reducers = []
      @uncompleted = targets.length

      @values = {}
      super(&block)

      @targets.each do |wiretap|
        @values[wiretap] = wiretap.value

        wiretap.listen do |value|
          @values[wiretap] = value
          trigger_changed(*@values.values)
        end

        wiretap.on_error do |error|
          trigger_error(error)
        end

        wiretap.and_then do |error|
          @uncompleted -= 1
          if @uncompleted == 0
            trigger_completed
          end
        end
      end
    end

    # Returns a Wiretap that combines all the values into one value whenever any
    # wiretap in `targets` is changed
    def reduce(&block)
      retval = WiretapReducer.new(block)
      @reducers << retval

      return retval
    end

    def trigger_changed(*values)
      super.tap do
        @reducers.each do |reducer|
          reducer.trigger_changed(*values)
        end
      end
    end

  end

  class WiretapReducer < Wiretap

    def initialize(reducer)
      @reducer = reducer
      super()
    end

    # passes the values through the reducer before passing up to the parent implementation
    def trigger_changed(*values)
      super(@reducer.call(*values))
    end

  end

end
