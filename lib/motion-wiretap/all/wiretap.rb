def MW(*args, &block)
  Motion.wiretap(*args, &block)
end

module MotionWiretap

  # This placeholder value is used anywhere you want to accept any value,
  # including nil.
  SINGLETON = Class.new.new

  class Wiretap
    # wiretaps have an intrinsic "current value"
    attr :value

    def initialize(&block)
      @is_torn_down = false
      @is_completed = false
      @is_error = false
      @queue = nil
      @value = nil

      @listener_handlers = []
      @completion_handlers = []
      @error_handlers = []

      listen &block if block
    end

    def dealloc
      self.cancel!
      super
    end

    # this is the preferred way to turn off a wiretap; child classes override
    # `teardown`, which is only ever called once.
    def cancel!
      return if @is_torn_down
      @is_torn_down = true
      teardown
    end

    # Overridden by subclasses to turn off observation, unregister
    # notifications, etc.
    def teardown
    end

    # specify the GCD queue that the listeners should be run on
    def queue(queue)
      @queue = queue
      return self
    end

    # send a block to the GCD queue
    def enqueue(&block)
      if @queue
        @queue.async(&block)
      else
        block.call
      end
    end

    ##|
    ##|  Wiretap events
    ##|

    # called when the value changes
    def listen(wiretap=nil, &block)
      raise "Block or Wiretap is expected in #{self.class.name}##{__method__}" unless block || wiretap
      raise "Only Block *or* Wiretap is expected in #{self.class.name}##{__method__}" if block && wiretap
      @listener_handlers << (block ? block.weak! : wiretap)
      self
    end

    def trigger_changed(*values)
      return if @is_torn_down || @is_completed || @is_error
      if values.length == 1
        @value = values.first
      else
        @value = values
      end

      @listener_handlers.each do |block_or_wiretap|
        trigger_changed_on(block_or_wiretap, values)
      end

      return self
    end

    # Sends the block or wiretap a changed signal
    def trigger_changed_on(block_or_wiretap, values)
      if block_or_wiretap.is_a? Wiretap
        block_or_wiretap.trigger_changed(*values)
      else
        enqueue do
          block_or_wiretap.call(*values)
        end
      end
    end

    # called when no more values are expected
    def and_then(wiretap=nil, &block)
      raise "Block or Wiretap is expected in #{self.class.name}##{__method__}" unless block || wiretap
      raise "Only Block *or* Wiretap is expected in #{self.class.name}##{__method__}" if block && wiretap
      @completion_handlers << (block ? block.weak! : wiretap)
      if @is_completed
        trigger_completed_on(block || wiretap)
      end
      return self
    end

    def trigger_completed
      return if @is_torn_down || @is_completed || @is_error
      @is_completed = true

      @completion_handlers.each do |block_or_wiretap|
        trigger_completed_on(block_or_wiretap)
      end

      cancel!
      return self
    end

    # Sends the block or wiretap a completed signal
    def trigger_completed_on(block_or_wiretap)
      if block_or_wiretap.is_a? Wiretap
        block_or_wiretap.trigger_completed
      else
        enqueue do
          block_or_wiretap.call
        end
      end
    end

    # called when an error occurs, and no more values are expected
    def on_error(wiretap=nil, &block)
      raise "Block or Wiretap is expected in #{self.class.name}##{__method__}" unless block || wiretap
      raise "Only Block *or* Wiretap is expected in #{self.class.name}##{__method__}" if block && wiretap
      @error_handlers << (block ? block.weak! : wiretap)
      if @is_error
        trigger_error_on(block || wiretap, @is_error)
      end
      return self
    end

    def trigger_error(error=SINGLETON)
      return if @is_torn_down || @is_completed || @is_error
      raise "You must pass a truthy value to `trigger_error()`" unless error

      # convert SINGLETON to a default error value
      error = true if error == SINGLETON
      @is_error = error

      @error_handlers.each do |block_or_wiretap|
        trigger_error_on(block_or_wiretap, error)
      end

      cancel!
      return self
    end

    # Sends the block or wiretap an error value
    def trigger_error_on(block_or_wiretap, error)
      if block_or_wiretap.is_a? Wiretap
        block_or_wiretap.trigger_error(error)
      else
        enqueue do
          block_or_wiretap.call(error)
        end
      end
    end

    ##|
    ##|  Wiretap Predicates
    ##|

    # Returns a Wiretap that will only be called if the &condition block returns
    # true
    def filter(&block)
      return WiretapFilter.new(self, block)
    end

    # Returns a Wiretap that combines all the values into one value (the values
    # are all passed in at the same time)
    # @example
    #     wiretap.combine do |one, two|
    #       one ? two : nil
    #     end
    def combine(&block)
      return WiretapCombiner.new(self, block)
    end

    # Returns a Wiretap that passes each value through the block, and also the
    # previous return value (memo).
    # @example
    #     # returns the total of all the prices
    #     wiretap.reduce(0) do |memo, item|
    #       memo + item.price
    #     end
    def reduce(memo=nil, &block)
      return WiretapReducer.new(self, memo, block)
    end

    # Returns a Wiretap that passes each value through the provided block
    # @example
    #     wiretap.map do |item|
    #       item.to_s
    #     end
    def map(&block)
      return WiretapMapper.new(self, block)
    end

  end

  class WiretapTarget < Wiretap
    attr :target

    def initialize(target, &block)
      @target = target
      super(&block)
    end

  end

  class WiretapKvo < WiretapTarget
    attr :property

    def initialize(target, property, &block)
      @property = property
      @initial_is_set = false
      @bound_to = []
      super(target, &block)

      @target.addObserver(self,
        forKeyPath: property.to_s,
        options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial,
        context: nil
        )
    end

    def teardown
      @target.removeObserver(self,
        forKeyPath: @property.to_s
        )
      @bound_to.each &:cancel!
      super
    end

    def bind_to(wiretap)
      @bound_to << wiretap
      wiretap.listen do |*values|
        @target.send("#{@property}=".to_sym, wiretap.value)
      end
      wiretap.trigger_changed(wiretap.value)

      return self
    end

    def observeValueForKeyPath(path, ofObject: target, change: change, context: context)
      value = change[NSKeyValueChangeNewKey]
      if @initial_is_set
        trigger_changed(value)
      else
        @value = value
        @initial_is_set = true
      end
    end

  end

  class WiretapArray < Wiretap
    attr :targets

    def initialize(targets, &block)
      raise "Not only is listening to an empty array pointless, it will also cause errors" if targets.length == 0

      # the complete trigger isn't called until all the wiretap are complete
      @uncompleted = targets.length

      # targets can be an array of Wiretap objects (they will be monitored), or
      # plain objects (they'll just be included in the sequence)
      super(&block)

      # gets assigned to the wiretap value if it's a Wiretap, or the object
      # itself if it is anything else.
      @values = []
      @initial_is_set = true
      # maps the wiretap object (which is unique)
      @wiretaps = {}

      targets.each_with_index do |wiretap, index|
        unless wiretap.is_a? Wiretap
          @values << wiretap
          # not a wiretap, so doesn't need to be "completed"
          @uncompleted -= 1
        else
          raise "You cannot store a Wiretap twice in the same sequence (for now - do you really need this?)" if @wiretaps.key?(wiretap)
          @wiretaps[wiretap] = index

          @values << wiretap.value

          wiretap.listen do |*values|
            indx = @wiretaps[wiretap]
            @values[indx] = wiretap.value
            trigger_changed(*@values)
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
    end

    def teardown
      cancel = (->(wiretap){ wiretap.cancel! }).weak!
      @wiretaps.keys.each &cancel
      super
    end

    def trigger_changed(*values)
      values = @values if values.length == 0
      super(*values)
    end

  end

  class WiretapChild < Wiretap

    def initialize(parent)
      @parent = parent
      @parent.listen(self)
      @value = @parent.value
      super()
    end

    def teardown
      @parent.cancel!
      super
    end

  end

  class WiretapFilter < WiretapChild

    def initialize(parent, filter)
      @filter = filter
      super(parent)
    end

    # passes the values through the filter before passing up to the parent
    # implementation
    def trigger_changed(*values)
      if @filter.call(*values)
        Wiretap.instance_method(:trigger_changed).bind(self).call(*values)
        # super
      end
    end

  end

  class WiretapCombiner < WiretapChild

    def initialize(parent, combiner)
      @combiner = combiner
      super(parent)
    end

    # passes the values through the combiner before passing up to the parent
    # implementation
    def trigger_changed(*values)
      super(@combiner.call(*values))
    end

  end

  class WiretapReducer < WiretapChild

    def initialize(parent, memo, reducer)
      @reducer = reducer
      @memo = memo
      super(parent)
    end

    # passes each value through the @reducer, passing in the return value of the
    # previous call (starting with @memo)
    def trigger_changed(*values)
      super(values.inject(@memo, &@reducer))
    end

  end

  class WiretapMapper < WiretapChild

    def initialize(parent, mapper)
      @mapper = mapper
      super(parent)
    end

    # passes the values through the mapper before passing up to the parent
    # implementation
    def trigger_changed(*values)
      super(*values.map { |value| @mapper.call(value) })
    end

  end

  class WiretapProc < WiretapTarget

    def initialize(target, queue, and_then)
      @started = false
      super(target)
      and_then(&and_then) if and_then
      queue(queue) if queue

      start if and_then
    end

    def start
      unless @started
        @started = true
        enqueue do
          begin
            if @target.arity == 0
              @target.call
            else
              @target.call(-> (value) { self.trigger_changed(value) })
            end
          rescue Exception => error
            trigger_error(error)
          else
            trigger_completed
          end
        end
      end
    end

  end

  class WiretapNotification < Wiretap

    def initialize(notification, object, block)
      super(&block)
      @notification = notification
      @object = object

      NSNotificationCenter.defaultCenter.addObserver(self, selector: 'notify:', name: @notification, object: @object)
    end

    def notify(notification)
      trigger_changed(notification.object, notification.userInfo)
    end

    def teardown
      NSNotificationCenter.defaultCenter.removeObserver(self, name: @notification, object: @object)
      super
    end

  end

end
