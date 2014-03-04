describe MotionWiretap::WiretapView do
  tests GestureController

  before do
    @wiretap_1 = Motion.wiretap(controller.gesture_button).on(:tap) do
      @gesture_touched = true
    end

    @wiretap_2 = Motion.wiretap(controller.control_event_button).on(:touch) do
      @control_event_touched = true
    end
  end

  it 'should be a MotionWiretap::WiretapView' do
    @wiretap_1.should.be.kind_of(MotionWiretap::WiretapView)
  end

  it 'should be a MotionWiretap::WiretapControl' do
    @wiretap_2.should.be.kind_of(MotionWiretap::WiretapControl)
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
