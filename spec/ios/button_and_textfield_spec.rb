describe "MotionWiretap with UIButtons and UITextFields" do

  before do
    @login_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @label = UILabel.new
    @username_field = UITextField.new
    @password_field = UITextField.new

    @label_wiretap = Motion.wiretap(@label, :text).bind_to(Motion.wiretap(@username_field, :text))
    # @login_button.enabled = false

    bound = Motion.wiretap([
        Motion.wiretap(@username_field, :text),
        Motion.wiretap(@password_field, :text),
      ]).combine do |username, password|
        username && username.length > 0 && password && password.length > 0
      end
    @button_wiretap = Motion.wiretap(@login_button, :enabled).bind_to(bound)
  end

  it "should start out disabled" do
    @login_button.enabled?.should == false

    @label_wiretap.cancel!
    @button_wiretap.cancel!
  end

  it "should not be enabled if only username field is set" do
    @username_field.text = 'username'
    @login_button.enabled?.should == false

    @label_wiretap.cancel!
    @button_wiretap.cancel!
  end

  it "should not be enabled if only password field is set" do
    @password_field.text = 'password'
    @login_button.enabled?.should == false

    @label_wiretap.cancel!
    @button_wiretap.cancel!
  end

  it "should be enabled if both fields are set" do
    @username_field.text = 'username'
    @password_field.text = 'password'
    @login_button.enabled?.should == true

    @label_wiretap.cancel!
    @button_wiretap.cancel!
  end

  it "should respond to a change in the textview" do
    @username_field.text = '@username'
    @username_field.sendActionsForControlEvents(UIControlEventEditingChanged)
    @label.text.should == '@username'

    @label_wiretap.cancel!
    @button_wiretap.cancel!
  end

end
