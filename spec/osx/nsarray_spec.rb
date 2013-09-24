describe "Motion Wiretap" do

  describe "monitoring an array of wiretap" do

    it "should have the `wiretap` method" do
      -> {
        [1].wiretap
      }.should.not.raise
    end

    it "should return a WiretapArray object" do
      [1].wiretap.should.is_a MotionWiretap::Wiretap
      [1].wiretap.should.is_a MotionWiretap::WiretapArray
    end

    it "should listen for changes on all objects" do
      p1 = Person.new
      p2 = Person.new
      [
        p1.wiretap(:name),
        p2.wiretap(:name),
      ].wiretap do |p1_name,p2_name|
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
      ].wiretap do |p1_name,p2_name|
        @times_called += 1
      end
      p1.name = 'name 1'
      p2.name = 'name 2'
      @times_called.should == 2
    end

    describe "should combine the values" do
      it "should combine Wiretap values" do
        @times_called = 0
        p1 = Person.new
        p2 = Person.new
        [
          p1.wiretap(:name),
          p2.wiretap(:name),
        ].wiretap.combine do |p1_name, p2_name|
          "#{p1_name} #{p2_name}"
        end.listen do |combined|
          @combined = combined
        end
        p1.name = 'name 1'
        p2.name = 'name 2'
        @combined.should == 'name 1 name 2'
      end

      it "should combine Wiretap values even when only one was changed" do
        @times_called = 0
        p1 = Person.new
        p2 = Person.new
        p2.name = 'name 2'
        [
          p1.wiretap(:name),
          p2.wiretap(:name),
        ].wiretap.combine do |p1_name, p2_name|
          "#{p1_name} #{p2_name}"
        end.listen do |combined|
          @combined = combined
        end
        p1.name = 'name 1'
        @combined.should == 'name 1 name 2'
      end
    end

    describe "should reduce the values" do
      it "should reduce Wiretap objects" do
        @times_called = 0
        p1 = Person.new
        p2 = Person.new
        [
          p1.wiretap(:name),
          p2.wiretap(:name),
        ].wiretap.reduce do |memo, name|
          if memo
            memo + (name ? ' ' : '')
          else
            ''
          end + (name || '')
        end.listen do |reduced|
          @reduced = reduced
        end
        p1.name = 'name 1'
        p2.name = 'name 2'
        @reduced.should == 'name 1 name 2'
      end

      it "should reduce Wiretap values even when only one was changed" do
        @times_called = 0
        p1 = Person.new
        p2 = Person.new
        p2.name = 'name 2'
        [
          p1.wiretap(:name),
          p2.wiretap(:name),
        ].wiretap.reduce do |memo, name|
          if memo
            memo + (name ? ' ' : '')
          else
            ''
          end + (name || '')
        end.listen do |reduced|
          @reduced = reduced
        end
        p1.name = 'name 1'
        @reduced.should == 'name 1 name 2'
      end

      it "should reduce all non-Wiretap objects" do
        @times_called = 0
        [
          'name 1',
          'name 2',
        ].wiretap.reduce do |memo, name|
          if memo
            memo + (name ? ' ' : '')
          else
            ''
          end + (name || '')
        end.listen do |reduced|
          @reduced = reduced
        end
        @reduced.should == 'name 1 name 2'
      end

      it "should reduce a mix of Wiretap and non-Wiretap objects" do
        @times_called = 0
        p1 = Person.new
        [
          p1.wiretap(:name),
          'name 2',
        ].wiretap.reduce do |memo, name|
          if memo
            memo + (name ? ' ' : '')
          else
            ''
          end + (name || '')
        end.listen do |reduced|
          @reduced = reduced
        end
        p1.name = 'name 1'
        @reduced.should == 'name 1 name 2'
      end
    end

  end

end
