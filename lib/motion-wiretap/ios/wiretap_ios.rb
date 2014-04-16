module MotionWiretap
  class GestureNotFound < Exception
  end

  class WiretapView < WiretapTarget

    def initialize(target, &block)
      super
      @gesture_recognizers = []
    end

    def on(recognizer, options=nil, &block)
      if recognizer
        case recognizer
        when :tap
          recognizer = Gestures.tap(self, options)
        when :pinch
          recognizer = Gestures.pinch(self, options)
        when :rotate
          recognizer = Gestures.rotate(self, options)
        when :swipe
          recognizer = Gestures.swipe(self, options)
        when :pan
          recognizer = Gestures.pan(self, options)
        when :press
          recognizer = Gestures.press(self, options)
        else
          raise GestureNotFound.new(recognizer.to_s)
        end

        self.target.addGestureRecognizer(recognizer)
        @gesture_recognizers << recognizer
      end

      listen(&block) if block

      return self
    end

    def handle_gesture(gesture)
      trigger_changed(gesture)
    end

    def teardown
      remove_gesture = (-> (recognizer) {
        self.target.removeGestureRecognizer(recognizer)
      }).weak!
      @gesture_recognizers.each(&remove_gesture)
      super
    end

  end

  class WiretapControl < WiretapView

    def initialize(target, &block)
      super
      @control_events = []
    end

    # control_event can be any UIControlEventConstant, or any symbol found in
    # wiretap_control_events.rb, or an array of UIControlEventConstants or
    # symbols.  Since UIView implements `on` to accept a gesture, this method
    # calls `super` when the symbol isn't a control
    def on(control_event, options={}, &block)
      begin
        control_event = ControlEvents.convert(control_event)
        self.target.addTarget(self, action: 'handle_event:', forControlEvents: control_event)
        @control_events << control_event
      rescue ControlEventNotFound
        super(control_event, options, &block)
      else
        super(nil, options, &block)
      end

      return self
    end

    def handle_event(event)
      trigger_changed(event)
    end

    def teardown
      remove_event = (-> (event) {
        self.target.removeTarget(self, action: 'handle_event:', forControlEvents: event)
      }).weak!
      @control_events.each(&remove_event)
      super
    end

  end

end
