describe "MotionWiretap with UIButtons and UITextFields" do

  before do
    @login_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @username_field = UITextField.new
    @password_field = UITextField.new

    @login_button.enabled = false
    @login_button.wiretap(:enabled).bind_to(
      [
        @username_field.wiretap(:text),
        @password_field.wiretap(:text),
      ].wiretaps.combine do |username, password|
        username && username.length > 0 && password && password.length > 0
      end
      )
  end

  it "should start out disabled" do
    @login_button.enabled?.should == false
  end

  it "should not be enabled if only username field is set" do
    @username_field.text = 'username'
    @login_button.enabled?.should == false
  end

  it "should not be enabled if only password field is set" do
    @password_field.text = 'password'
    @login_button.enabled?.should == false
  end

  it "should be enabled if both fields are set" do
    @username_field.text = 'username'
    @password_field.text = 'password'
    @login_button.enabled?.should == true
  end

end
