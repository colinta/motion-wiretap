describe MotionWiretap::WiretapNotification do

  before do
    @notification_received = false
    @notification_object = nil
    @notification_info = nil
  end

  it "should listen for notifications" do
    notification_name = 'NotificationName'
    notification = Motion.wiretap(notification_name) do
      @notification_received = true
    end
    NSNotificationCenter.defaultCenter.postNotificationName(notification_name, object:nil)
    @notification_received.should == true
  end

  it "should get object from notifications" do
    notification_name = 'NotificationName'
    @foo = Class.new.new
    notification = Motion.wiretap(notification_name) do |object|
      @notification_received = true
      @notification_object = object
    end
    NSNotificationCenter.defaultCenter.postNotificationName(notification_name, object: @foo)
    @notification_received.should == true
    @notification_object.should == @foo
  end

  it "should get userInfo from notifications" do
    notification_name = 'NotificationName'
    @foo = Class.new.new
    @user_info = { 'foo' => 'foo!' }
    notification = Motion.wiretap(notification_name) do |object, info|
      @notification_received = true
      @notification_object = object
      @notification_info = info
    end
    NSNotificationCenter.defaultCenter.postNotificationName(notification_name, object: @foo, userInfo: @user_info)
    @notification_object.should == @foo
    @notification_info.should == @user_info
    @notification_info['foo'].should == @user_info['foo']
  end

end
