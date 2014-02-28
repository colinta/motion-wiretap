class UIView

  def wiretap(property=nil, &block)
    if property.nil?
      MotionWiretap::WiretapView.new(self, &block)
    else
      MotionWiretap::WiretapKvo.new(self, property, &block)
    end
  end

end


class UIControl

  def wiretap(property=nil, &block)
    if property.nil?
      MotionWiretap::WiretapControl.new(self, &block)
    else
      MotionWiretap::WiretapKvo.new(self, property, &block)
    end
  end

end
