describe "MotionWiretap with lots of chaining" do

  tests ChainingController

  before do
    @done = false
    @touched = false

    @wiretap_1 = 
      MW([
        MW(controller.username_field, :text),
        MW(controller.password_field, :text)
      ])
      .combine do |username, password|
        !!(username && password && username.length > 0 && password.length > 0)
      end

    @wiretap_2 = 
      MW([@wiretap_1, MW(controller.login_button).on(:touch)])
      .combine { |enabled, touched| !!(enabled && touched) }
      .filter { |doing| !!doing }
      .listen do |enabled, touched|
        @done = true
      end

    @wiretap_3 = MW(controller.login_button).on(:touch).listen do |e|
      @touched = true
    end
  end

  it "should start with undone" do
    @done.should == false
  end

  it "it should be done when all is ready" do
    controller.username_field.text = 'username'
    controller.password_field.text = 'password'

    tap controller.login_button

    test = -> do
      @wiretap_1.cancel!
      @wiretap_2.cancel!
      @done.should == true
    end

    if @touched
      test.call
    else
      print "\nyou have 5 seconds to tap 'control_event_button'"
      wait 5, &test
    end
  end

end
