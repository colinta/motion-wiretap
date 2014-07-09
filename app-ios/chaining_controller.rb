class ChainingController < UIViewController
  attr :login_button
  attr :username_field
  attr :password_field

  def loadView
    super

    @username_field = UITextField.new
    @password_field = UITextField.new

    @login_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @login_button.accessibilityLabel = 'login_button'
    @login_button.setTitle('login_button', forState: UIControlStateNormal)
    @login_button.sizeToFit
    @login_button.center = [view.frame.size.width / 2, view.frame.size.height / 2 + 50]

    view.addSubview @login_button
    view.addSubview @username_field
    view.addSubview @password_field
  end
end
