$motion_wiretaps = []

module MotionWiretap

  class Wiretap

    def initialize(&block)
      $motion_wiretaps << self  # signal will be removed when it is completed

      @is_torn_down = false
      @is_completed = false
      @is_error = false
      @queue = nil

      @listener_handlers = []
      @completion_handlers = []
      @error_handlers = []

      listen &block if block
    end

    def dealloc
      teardown
      super
    end

    # this is the preferred way to turn off a wiretap
    def cancel!
      teardown
    end

    # for internal use
    def teardown
      return if @is_torn_down

      @is_torn_down = true
      $motion_wiretaps.delete(self)
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
      @listener_handlers << (block || wiretap)
      self
    end

    def trigger_changed(*values)
      return if @is_torn_down || @is_completed || @is_error

      @listener_handlers.each do |block_or_wiretap|
        trigger_changed_on(block_or_wiretap, values)
      end

      return self
    end

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
      @completion_handlers << (block || wiretap)
      if @is_completed
        trigger_completed_on(block || wiretap)
      end
      self
    end

    def trigger_completed
      return if @is_torn_down || @is_completed || @is_error
      @is_completed = true

      @completion_handlers.each do |block_or_wiretap|
        trigger_completed_on(block_or_wiretap)
      end

      teardown
      return self
    end

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
      @error_handlers << (block || wiretap)
      if @is_error
        trigger_error_on(block || wiretap, @is_error)
      end
      self
    end

    def trigger_error(error)
      return if @is_torn_down || @is_completed || @is_error
      error ||= true
      @is_error = error

      @error_handlers.each do |block_or_wiretap|
        trigger_error_on(block_or_wiretap, error)
      end

      teardown
      return self
    end

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
    def combine(&block)
      return WiretapCombiner.new(self, block)
    end

    # Returns a Wiretap that passes each value through the block, and also the
    # previous return value (memo).
    # @example
    #     wiretap.reduce(0) do |memo, item|
    #       memo + item.price
    #     end
    #     # returns the total of all the prices
    def reduce(memo=nil, &block)
      return WiretapReducer.new(self, memo, block)
    end

    # Returns a Wiretap that passes each value through the provided block
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

    def teardown
      @target = nil
      super
    end

  end

  class WiretapKvo < WiretapTarget
    attr :property
    attr :value

    def initialize(target, property, &block)
      @property = property
      @value = nil
      @initial_is_set = false
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
      @property = nil
      @value = nil
      super
    end

    def trigger_changed(*values)
      super(@value)
    end

    def bind_to(wiretap)
      wiretap.listen do |value|
        @target.send("#{@property}=", value)
      end
      wiretap.trigger_changed
    end

    def observeValueForKeyPath(path, ofObject: target, change: change, context: context)
      @value = change[NSKeyValueChangeNewKey]
      if @initial_is_set
        trigger_changed(@value)
      else
        @initial_is_set = true
      end
    end

  end

  class WiretapArray < WiretapTarget
    attr :targets

    def initialize(targets, &block)
      raise "Not only is listening to an empty array pointless, it will also cause errors" if targets.length == 0

      # the complete trigger isn't called until all the wiretaps are complete
      @uncompleted = targets.length

      # targets can be an array of Wiretap objects (they will be monitored), or
      # plain objects (they'll just be included in the sequence)
      super(targets, &block)

      # gets assigned to the wiretap value if it's a Wiretap, or the object
      # itself if it is anything else.
      @value = []
      @initial_is_set = true
      # maps the wiretap object (which is unique)
      @wiretaps = {}

      targets.each_with_index do |wiretap,index|
        unless wiretap.is_a? Wiretap
          @value << wiretap
          # not a wiretap, so doesn't need to be "completed"
          @uncompleted -= 1
        else
          raise "You cannot store a Wiretap twice in the same sequence (for now - do you really need this?)" if @wiretaps.key?(wiretap)
          @wiretaps[wiretap] = index

          @value << wiretap.value

          wiretap.listen do |value|
            indx = @wiretaps[wiretap]
            @value[index] = wiretap.value
            trigger_changed(*@value)
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
      super
      @wiretaps = nil
    end

    def trigger_changed(*values)
      values = @value if values.length == 0
      super(*values)
    end

  end

  class WiretapFilter < Wiretap

    def initialize(parent, filter)
      @parent = parent
      @filter = filter

      @parent.listen(self)

      super()
    end

    # passes the values through the filter before passing up to the parent
    # implementation
    def trigger_changed(*values)
      if ( @filter.call(*values) )
        super(*values)
      end
    end

    def teardown
      super
      @parent = nil
    end

  end

  class WiretapCombiner < Wiretap

    def initialize(parent, combiner)
      @parent = parent
      @combiner = combiner

      @parent.listen(self)

      super()
    end

    # passes the values through the combiner before passing up to the parent
    # implementation
    def trigger_changed(*values)
      super(@combiner.call(*values))
    end

    def teardown
      super
      @parent = nil
    end

  end

  class WiretapReducer < Wiretap

    def initialize(parent, memo, reducer)
      @parent = parent
      @reducer = reducer
      @memo = memo

      @parent.listen(self)

      super()
    end

    # passes each value through the @reducer, passing in the return value of the
    # previous call (starting with @memo)
    def trigger_changed(*values)
      super(values.inject(@memo, &@reducer))
    end

    def teardown
      super
      @parent = nil
    end

  end

  class WiretapMapper < Wiretap

    def initialize(parent, mapper)
      @parent = parent
      @mapper = mapper

      @parent.listen(self)

      super()
    end

    # passes the values through the mapper before passing up to the parent
    # implementation
    def trigger_changed(*values)
      super(*values.map { |value| @mapper.call(value) })
    end

    def teardown
      super
      @parent = nil
    end

  end

  class WiretapProc < WiretapTarget

    def initialize(target, queue, block)
      @started = false
      super(target)
      and_then(&block) if block
      queue(queue) if queue

      start if block
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

end
