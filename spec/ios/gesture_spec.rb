describe "MotionWiretap with UIView gestures" do
  tests GestureController

  before do
    controller.gesture_button.wiretap.on(:tap) do
      @gesture_touched = true
    end
    controller.control_event_button.wiretap.on(:touch) do
      @control_event_touched = true
    end
  end

  it 'should respond to tap' do
    tap 'gesture_button'
    @gesture_touched.should == true
  end

  it 'should respond to touch' do
    tap 'control_event_button'
    @control_event_touched.should == true
  end

end
