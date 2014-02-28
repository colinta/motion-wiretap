module Motion

  module_function

  def wiretap(target, property=nil, &block)
    case target
    when NSString
      MotionWiretap::WiretapNotification.new(target, property, block)
    when Proc
      MotionWiretap::WiretapProc.new(target, property, block)
    when NSArray
      MotionWiretap::WiretapArray.new(target, &block)
    when NSView
      if property.nil?
        MotionWiretap::WiretapView.new(target, &block)
      else
        MotionWiretap::WiretapKvo.new(target, property, &block)
      end
    when NSObject
      MotionWiretap::WiretapKvo.new(target, property, &block)
    end
  end

end
