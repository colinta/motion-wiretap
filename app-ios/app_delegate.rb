class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    return true if RUBYMOTION_ENV == 'test'

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    ctlr = GestureController.new
    @window.rootViewController = ctlr
    @window.makeKeyAndVisible
    true
  end
end
