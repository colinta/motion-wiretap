module MotionWiretap

  class WiretapView < WiretapTarget

    def on(recognizer, options=nil, &block)
      case recognizer
      when :tap
        recognizer = MotionWiretap::Gestures.tap(self, options)
      when :pinch
        recognizer = MotionWiretap::Gestures.pinch(self, options)
      when :rotate
        recognizer = MotionWiretap::Gestures.rotate(self, options)
      when :swipe
        recognizer = MotionWiretap::Gestures.swipe(self, options)
      when :pan
        recognizer = MotionWiretap::Gestures.pan(self, options)
      when :press
        recognizer = MotionWiretap::Gestures.press(self, options)
      end

      self.target.addGestureRecognizer(recognizer)
      listen(&block) if block
      return self
    end

    def handle_gesture(recognizer)
      trigger_changed
    end

  end

  class WiretapControl < WiretapView

    # control_event can be any UIControlEventconstant, or any symbol found in
    # wiretap_control_events.rb, or an array of UIControlEvent constants or
    # symbols.
    def on(control_event, options={}, &block)
      begin
        control_event = ControlEvents.convert(control_event)
        self.target.addTarget(self, action:'handle_event:', forControlEvents:control_event)
        listen(&block) if block
      rescue ControlEventNotFound
        super(control_event, options, &block)
      end

      return self
    end

    def handle_event(event)
      trigger_changed
    end

  end

end
