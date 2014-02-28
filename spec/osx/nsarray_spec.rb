describe MotionWiretap do

  describe "monitoring an array of wiretaps" do

    it "should have the `wiretap` method" do
      -> {
        Motion.wiretap([1])
      }.should.not.raise
    end

    it "should return a WiretapArray object" do
      Motion.wiretap([1]).should.is_a MotionWiretap::Wiretap
      Motion.wiretap([1]).should.is_a MotionWiretap::WiretapArray
    end

    it "should listen for changes on all objects" do
      p1 = Person.new
      p2 = Person.new
      Motion.wiretap([
        Motion.wiretap(p1, :name),
        Motion.wiretap(p2, :name),
      ]) do |p1_name,p2_name|
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
      Motion.wiretap([
        Motion.wiretap(p1, :name),
        Motion.wiretap(p2, :name),
      ]) do |p1_name,p2_name|
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
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).combine do |p1_name, p2_name|
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
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).combine do |p1_name, p2_name|
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
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).reduce do |memo, name|
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
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).reduce do |memo, name|
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
        Motion.wiretap([
          'name 1',
          'name 2',
        ]).reduce do |memo, name|
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
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          'name 2',
        ]).reduce do |memo, name|
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
