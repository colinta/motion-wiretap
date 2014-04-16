describe MotionWiretap::WiretapView do
  tests GestureController

  before do
    @wiretap_1 = Motion.wiretap(controller.gesture_button).on(:tap) do |gesture|
      @gesture_touched = true
    end

    @wiretap_2 = Motion.wiretap(controller.control_event_button).on(:touch) do |event|
      @control_event_touched = true
    end
  end

  it 'should be a MotionWiretap::WiretapView' do
    @wiretap_1.should.be.kind_of(MotionWiretap::WiretapView)
  end

  it 'should be a MotionWiretap::WiretapControl' do
    @wiretap_2.should.be.kind_of(MotionWiretap::WiretapControl)
  end

  describe MotionWiretap::Gestures do
    before do
      @wiretap = MotionWiretap::Signal.new
      @delegate = UIViewController.new
    end

    it 'should support options on tap' do
      gesture = MotionWiretap::Gestures.tap(@wiretap, 2)
      gesture.numberOfTapsRequired.should == 2
      gesture = MotionWiretap::Gestures.tap(@wiretap,
        taps: 2,
        fingers: 2,
        delegate: @delegate,
        )
      gesture.numberOfTapsRequired.should == 2
      gesture.numberOfTouchesRequired.should == 2
      gesture.delegate.should == @delegate
    end
    it 'should support options on pinch' do
      gesture = MotionWiretap::Gestures.pinch(@wiretap, 0.5)
      gesture.scale.should == 0.5
      gesture = MotionWiretap::Gestures.pinch(@wiretap,
        scale: 0.5,
        delegate: @delegate,
        )
      gesture.scale.should == 0.5
      gesture.delegate.should == @delegate
    end
    it 'should support options on rotate' do
      gesture = MotionWiretap::Gestures.rotate(@wiretap, 1)
      gesture.rotation.should == 1
      gesture = MotionWiretap::Gestures.rotate(@wiretap,
        rotation: 1,
        delegate: @delegate,
        )
      gesture.rotation.should == 1
      gesture.delegate.should == @delegate
    end
    it 'should support options on swipe' do
      gesture = MotionWiretap::Gestures.swipe(@wiretap, :left)
      gesture.direction.should == UISwipeGestureRecognizerDirectionLeft
      gesture = MotionWiretap::Gestures.swipe(@wiretap,
        direction: :left,
        fingers: 2,
        delegate: @delegate,
        )
      gesture.direction.should == UISwipeGestureRecognizerDirectionLeft
      gesture.numberOfTouchesRequired.should == 2
      gesture.delegate.should == @delegate
    end
    it 'should support options on pan' do
      gesture = MotionWiretap::Gestures.pan(@wiretap, 2)
      gesture.maximumNumberOfTouches.should == 2
      gesture.minimumNumberOfTouches.should == 2
      gesture = MotionWiretap::Gestures.pan(@wiretap,
        fingers: 2,
        delegate: @delegate,
        )
      gesture.maximumNumberOfTouches.should == 2
      gesture.minimumNumberOfTouches.should == 2
      gesture.delegate.should == @delegate
      gesture = MotionWiretap::Gestures.pan(@wiretap,
        min_fingers: 1,
        max_fingers: 3,
        delegate: @delegate,
        )
      gesture.maximumNumberOfTouches.should == 1
      gesture.minimumNumberOfTouches.should == 3
      gesture.delegate.should == @delegate
    end
    it 'should support options on press' do
      gesture = MotionWiretap::Gestures.press(@wiretap, 1)
      gesture.minimumPressDuration.should == 1
      gesture = MotionWiretap::Gestures.press(@wiretap,
        duration: 1,
        taps: 2,
        fingers: 2,
        delegate: @delegate,
        )
      gesture.minimumPressDuration.should == 1
      gesture.numberOfTapsRequired.should == 2
      gesture.numberOfTouchesRequired.should == 2
      gesture.delegate.should == @delegate
    end
  end

  it 'should respond to tap' do
    tap controller.gesture_button
    test = -> do
      @gesture_touched.should == true
      @wiretap_1.cancel!
      @wiretap_2.cancel!
    end
    if @gesture_touched
      test.call
    else
      print "\nyou have 5 seconds to tap 'gesture_button'"
      wait 2 do
        if @gesture_touched
          test.call
        else
          wait 3, &test
        end
      end
    end
  end

  it 'should respond to touch' do
    tap controller.control_event_button
    test = -> do
      @control_event_touched.should == true
      @wiretap_1.cancel!
      @wiretap_2.cancel!
    end
    if @control_event_touched
      test.call
    else
      print "\nyou have 1 second to tap 'control_event_button'"
      wait 1, &test
    end
  end

end
