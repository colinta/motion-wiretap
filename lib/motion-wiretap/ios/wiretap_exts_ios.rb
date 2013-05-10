class UIView

  def wiretap(property, &block)
    MotionWiretap::WiretapView.new(self, property, &block)
  end

end
