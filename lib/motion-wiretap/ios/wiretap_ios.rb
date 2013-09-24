module MotionWiretap
  class GestureNotFound < Exception
  end

  class WiretapView < Wiretap

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
      end

      super(&block)

      return self
    end

    def handle_gesture(recognizer)
      trigger_changed
    end

  end

  class WiretapControl < WiretapView

    # control_event can be any UIControlEventConstant, or any symbol found in
    # wiretap_control_events.rb, or an array of UIControlEventConstants or
    # symbols.  Since UIView implements `on` to accept a gesture, this method
    # calls `super` when the symbol isn't a control
    def on(control_event, options={}, &block)
      begin
        control_event = ControlEvents.convert(control_event)
        self.target.addTarget(self, action:'handle_event:', forControlEvents:control_event)
      rescue ControlEventNotFound
        super(control_event, options, &block)
      else
        super(nil, options, &block)
      end

      return self
    end

    def handle_event(event)
      trigger_changed
    end

  end

end
