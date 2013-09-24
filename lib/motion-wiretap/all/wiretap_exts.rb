class NSObject

  def wiretap(property, &block)
    MotionWiretap::WiretapKvo.new(self, property, &block)
  end

end


class NSArray

  def wiretap(&block)
    MotionWiretap::WiretapArray.new(self, &block)
  end

end


class Proc

  def wiretap(queue=nil, &block)
    MotionWiretap::WiretapProc.new(self, queue, block)
  end

end


class NSString

  def wiretap(object=nil, &block)
    MotionWiretap::WiretapNotification(self, object, block)
  end

end
