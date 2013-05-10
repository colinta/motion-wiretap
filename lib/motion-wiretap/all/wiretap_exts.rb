class NSObject

  def wiretap(property, &block)
    MotionWiretap::WiretapKvo.new(self, property, &block)
  end

end


class NSArray

  def wiretap(property=nil, &block)
    raise "`wiretap` is not supported on Arrays.  Did you mean `wiretaps`?"
  end

  def wiretaps(&block)
    MotionWiretap::WiretapArray.new(self, &block)
  end

end
