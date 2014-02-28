class GestureController < UIViewController
  attr :gesture_button
  attr :control_event_button
  attr_reader :touched

  def loadView
    super

    @gesture_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @gesture_button.accessibilityLabel = 'gesture_button'
    @gesture_button.setTitle('gesture_button', forState: UIControlStateNormal)
    @gesture_button.sizeToFit
    @gesture_button.center = [self.view.frame.size.width / 2, self.view.frame.size.height / 2]

    @control_event_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @control_event_button.accessibilityLabel = 'control_event_button'
    @control_event_button.setTitle('control_event_button', forState: UIControlStateNormal)
    @control_event_button.sizeToFit
    @control_event_button.center = [self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 50]

    self.view.addSubview(@gesture_button)
    self.view.addSubview(@control_event_button)
  end

end
