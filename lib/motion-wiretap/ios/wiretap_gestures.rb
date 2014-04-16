module MotionWiretap
  # Some gesture recognizer translators.  Based on SugarCube's gesture recognizer
  # methods.
  module Gestures
    module_function

    # @yield [recognizer] Handles the gesture event, and passes the recognizer instance to the block.
    # @overload tap(taps)
    #   @param taps [Fixnum] Number of taps
    # @overload tap(options)
    #   @option options [Fixnum] :taps Number of taps before gesture is recognized
    #   @option options [Fixnum] :fingers Number of fingers before gesture is recognized
    def tap(target, taps_or_options=nil)
      taps = nil
      fingers = nil
      delegate = nil

      if taps_or_options
        if taps_or_options.is_a? Hash
          taps = taps_or_options[:taps]
          fingers = taps_or_options[:fingers]
          delegate = taps_or_options[:delegate]
        else
          taps = taps_or_options
        end
      end

      recognizer = UITapGestureRecognizer.alloc.initWithTarget(target, action: 'handle_gesture:')
      recognizer.numberOfTapsRequired = taps if taps
      recognizer.numberOfTouchesRequired = fingers if fingers
      recognizer.delegate = delegate if delegate
      return recognizer
    end

    # @yield [recognizer] Handles the gesture event, and passes the recognizer instance to the block.
    def pinch(target, options=nil)
      delegate = nil

      if options
        if options.is_a? Hash
          delegate = options[:delegate]
        end
      end

      recognizer = UIPinchGestureRecognizer.alloc.initWithTarget(target, action: 'handle_gesture:')
      recognizer.delegate = delegate if delegate
      return recognizer
    end

    # @yield [recognizer] Handles the gesture event, and passes the recognizer instance to the block.
    def rotate(target, options=nil)
      delegate = nil

      if options
        if options.is_a? Hash
          delegate = options[:delegate]
        else
        end
      end

      recognizer = UIRotationGestureRecognizer.alloc.initWithTarget(target, action: 'handle_gesture:')
      recognizer.delegate = delegate if delegate
      return recognizer
    end

    # @yield [recognizer] Handles the gesture event, and passes the recognizer instance to the block.
    # @overload swipe(taps)
    #   @param direction [Fixnum] Direction of swipe
    # @overload swipe(options)
    #   @option options [Fixnum] :fingers Number of fingers before gesture is recognized
    #   @option options [Fixnum, Symbol] :direction Direction of swipe, as a UISwipeGestureRecognizerDirection constant or a symbol (`:left, :right, :up, :down`)
    def swipe(target, direction_or_options)
      direction = nil
      fingers = nil
      delegate = nil

      if direction_or_options
        if direction_or_options.is_a? Hash
          direction = direction_or_options[:direction]
          fingers = direction_or_options[:fingers]
          delegate = direction_or_options[:delegate]
        else
          direction = direction_or_options
        end
      end

      case direction
      when :left
        direction = UISwipeGestureRecognizerDirectionLeft
      when :right
        direction = UISwipeGestureRecognizerDirectionRight
      when :up
        direction = UISwipeGestureRecognizerDirectionUp
      when :down
        direction = UISwipeGestureRecognizerDirectionDown
      end

      recognizer = UISwipeGestureRecognizer.alloc.initWithTarget(target, action: 'handle_gesture:')
      recognizer.direction = direction if direction
      recognizer.numberOfTouchesRequired = fingers if fingers
      recognizer.delegate = delegate if delegate
      return recognizer
    end

    # @yield [recognizer] Handles the gesture event, and passes the recognizer instance to the block.
    # @overload tap(taps)
    #   @param taps [Fixnum] Number of taps
    # @overload tap(options)
    #   @option options [Fixnum] :min_fingers Minimum umber of fingers for gesture to be recognized
    #   @option options [Fixnum] :max_fingers Maximum number of fingers for gesture to be recognized
    #   @option options [Fixnum] :fingers If min_fingers or max_fingers is not assigned, this will be the default.
    def pan(target, fingers_or_options=nil)
      fingers = nil
      min_fingers = nil
      max_fingers = nil
      delegate = nil

      if fingers_or_options
        if fingers_or_options.is_a? Hash
          fingers = fingers_or_options[:fingers]
          min_fingers = fingers_or_options[:min_fingers]
          max_fingers = fingers_or_options[:max_fingers]
          delegate = fingers_or_options[:delegate]
        else
          fingers = fingers_or_options
        end
      end

      # if fingers is assigned, but not min/max, assign it as a default
      min_fingers ||= fingers
      max_fingers ||= fingers

      recognizer = UIPanGestureRecognizer.alloc.initWithTarget(target, action: 'handle_gesture:')
      recognizer.maximumNumberOfTouches = min_fingers if min_fingers
      recognizer.minimumNumberOfTouches = max_fingers if max_fingers
      recognizer.delegate = delegate if delegate
      return recognizer
    end

    # @yield [recognizer] Handles the gesture event, and passes the recognizer instance to the block.
    # @overload press(duration)
    #   @param duration [Fixnum] How long in seconds before gesture is recognized
    # @overload press(options)
    #   @option options [Fixnum] :duration How long in seconds before gesture is recognized
    #   @option options [Fixnum] :taps Number of taps before gesture is recognized
    #   @option options [Fixnum] :fingers Number of fingers before gesture is recognized
    def press(target, duration_or_options=nil)
      duration = nil
      taps = nil
      fingers = nil
      delegate = nil

      if duration_or_options
        if duration_or_options.is_a? Hash
          duration = duration_or_options[:duration]
          taps = duration_or_options[:taps]
          fingers = duration_or_options[:fingers]
          delegate = duration_or_options[:delegate]
        else
          duration = duration_or_options
        end
      end

      recognizer = UILongPressGestureRecognizer.alloc.initWithTarget(target, action: 'handle_gesture:')
      recognizer.minimumPressDuration = duration if duration
      recognizer.numberOfTapsRequired = taps if taps
      recognizer.numberOfTouchesRequired = fingers if fingers
      recognizer.delegate = delegate if delegate
      return recognizer
    end

  end

end
