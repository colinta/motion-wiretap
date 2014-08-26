describe MotionWiretap::WiretapArray do

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
      @p1_name.should == 'name 1'
      p2.name = 'name 2'
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

    describe "it should call the completion block when all signals are complete" do

      it "should call immediately with one wiretap" do
        @complete = false
        tap = MotionWiretap::Signal.new
        Motion.wiretap([
          tap
        ]).and_then do
          @complete = true
        end

        @complete.should == false
        tap.next(nil)
        @complete.should == false
        tap.complete
        @complete.should == true
      end

      it "should call after two wiretaps" do
        @complete = false
        tap_1 = MotionWiretap::Signal.new
        tap_2 = MotionWiretap::Signal.new
        Motion.wiretap([
          tap_1,
          tap_2,
        ]).and_then do
          @complete = true
        end

        @complete.should == false
        tap_1.complete
        @complete.should == false
        tap_2.next(nil)
        @complete.should == false
        tap_2.complete
        @complete.should == true
      end

    end

    describe "should combine the values" do
      it "should combine Wiretap values" do
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
      before do
        @reduced = nil
      end

      it "should reduce Wiretap objects" do
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
        @reduced.should == 'name 1'
        p2.name = 'name 2'
        @reduced.should == 'name 1 name 2'
      end

      it "should reduce Wiretap objects and use a memo" do
        p1 = Person.new
        p2 = Person.new
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).reduce('names:') do |memo, name|
          memo + (name ? ' ' + name : '')
        end.listen do |reduced|
          @reduced = reduced
        end
        p1.name = 'name 1'
        @reduced.should == 'names: name 1'
        p2.name = 'name 2'
        @reduced.should == 'names: name 1 name 2'
      end

      it "should reduce Wiretap values even when only one was changed" do
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

      it "should reduce with an initial value" do
        p1 = Person.new

        Motion.wiretap(p1, :name)
        .reduce(3) do |memo, name|
          memo + (name || 0)
        end.listen do |reduced|
          @reduced = reduced
        end

        p1.name = 1
        @reduced.should == 4
        p1.name = 2
        @reduced.should == 6
        p1.name = 3
        @reduced.should == 9
      end

      it "should reduce a mix of Wiretap and non-Wiretap objects" do
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

    describe "should map the values" do
      before do
        @mapped = nil
      end

      it "should map Wiretap objects" do
        p1 = Person.new
        p2 = Person.new
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).map do |name|
          name && name.upcase
        end.listen do |p1_name, p2_name|
          @mapped = "#{p1_name} #{p2_name}"
        end
        p1.name = 'name 1'
        p2.name = 'name 2'
        @mapped.should == 'NAME 1 NAME 2'
      end

      it "should map Wiretap values even when only one was changed" do
        p1 = Person.new
        p2 = Person.new
        p2.name = 'name 2'
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          Motion.wiretap(p2, :name),
        ]).map do |name|
          name && name.upcase
        end.listen do |p1_name, p2_name|
          @mapped = "#{p1_name} #{p2_name}"
        end
        p1.name = 'name 1'
        @mapped.should == 'NAME 1 NAME 2'
      end

      it "should map all non-Wiretap objects" do
        Motion.wiretap([
          'name 1',
          'name 2',
        ]).map do |name|
          name && name.upcase
        end.listen do |p1_name, p2_name|
          @mapped = "#{p1_name} #{p2_name}"
        end
        @mapped.should == 'NAME 1 NAME 2'
      end

      it "should map a mix of Wiretap and non-Wiretap objects" do
        p1 = Person.new
        Motion.wiretap([
          Motion.wiretap(p1, :name),
          'name 2',
        ]).map do |name|
          name && name.upcase
        end.listen do |p1_name, p2_name|
          @mapped = "#{p1_name} #{p2_name}"
        end
        p1.name = 'name 1'
        @mapped.should == 'NAME 1 NAME 2'
      end
    end

  end

end
