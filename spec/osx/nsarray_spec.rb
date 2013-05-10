describe "Motion Wiretap" do

  describe "monitoring an array of wiretaps" do

    it "should have the `wiretaps` method" do
      -> {
        [].wiretaps
      }.should.not.raise
    end

    it "should return a WiretapArray object" do
      [].wiretaps.should.is_a MotionWiretap::Wiretap
      [].wiretaps.should.is_a MotionWiretap::WiretapArray
    end

    it "should listen for changes on all objects" do
      p1 = Person.new
      p2 = Person.new
      [
        p1.wiretap(:name),
        p2.wiretap(:name),
      ].wiretaps do |p1_name,p2_name|
        @p1_name = p1_name
        @p2_name = p2_name
      end
      p1.name = 'name 1'
      p2.name = 'name 2'
      @p1_name.should == 'name 1'
      @p2_name.should == 'name 2'
    end

    it "should call the handler on every change" do
      @times_called = 0
      p1 = Person.new
      p2 = Person.new
      [
        p1.wiretap(:name),
        p2.wiretap(:name),
      ].wiretaps do |p1_name,p2_name|
        @times_called += 1
      end
      p1.name = 'name 1'
      p2.name = 'name 2'
      @times_called.should == 2
    end

    it "should reduce the values" do
      @times_called = 0
      p1 = Person.new
      p2 = Person.new
      [
        p1.wiretap(:name),
        p2.wiretap(:name),
      ].wiretaps.reduce do |p1_name, p2_name|
        "#{p1_name} #{p2_name}"
      end.listen do |combined|
        @combined = combined
      end
      p1.name = 'name 1'
      p2.name = 'name 2'
      @combined.should == 'name 1 name 2'
    end

    it "should reduce the values even when only one was changed" do
      @times_called = 0
      p1 = Person.new
      p2 = Person.new
      p2.name = 'name 2'
      reducer = [
        p1.wiretap(:name),
        p2.wiretap(:name),
      ].wiretaps.reduce do |p1_name, p2_name|
        "#{p1_name} #{p2_name}"
      end
      reducer.listen do |combined|
        @combined = combined
      end
      p1.name = 'name 1'
      @combined.should == 'name 1 name 2'
    end

  end

end
