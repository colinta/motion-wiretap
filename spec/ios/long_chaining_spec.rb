describe "MotionWiretap with lots of chaining" do

  before do
    @login_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @username_field = UITextField.new
    @password_field = UITextField.new

    # i don't want to set the value of @login_button.enabled, but we need to
    # have the method compiled.
    UIButton.new.enabled = true

    @done = false
    @login_enabled_signal = 
      MW([
        MW(@username_field, :text),
        MW(@password_field, :text)
      ])
      .combine do |username, password|
        username && password && username.length > 0 && password.length > 0
      end

    @do_login_signal = 
      MW([@login_enabled_signal, MW(@login_button).on(:touch)])
      .combine { |enabled, touched| enabled && touched }
      .filter { |doing| doing }
      .listen do |doing|
        @done = true
      end
  end

  after do
    @login_enabled_signal.cancel!
    @do_login_signal.cancel!
  end

  it "should start with undone" do
    @done.should == false
  end

  it "it should be done when all is ready" do
    @username_field.text = 'username'
    @password_field.text = 'password'
    tap @login_button
    @done.should == true
  end

end
