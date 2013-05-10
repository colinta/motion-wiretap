describe "Motion Wiretap" do

  describe "monitoring changes to a model" do

    it "should have the `wiretap` method" do
      ->{
        Person.new.wiretap(:name)
      }.should.not.raise
    end

    it "should return a Wiretap object" do
      Person.new.wiretap(:name).should.is_a MotionWiretap::Wiretap
    end

    it "should call a block when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name) do |new_name|
        @name = new_name
      end
      person.name = new_name
      @name.should == new_name
    end

    it "should call a block only after a change" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      @times_called = 0
      person.wiretap(:name) do |new_name|
        @times_called += 1
      end
      person.name = new_name
      @times_called.should == 1
    end

    it "should call `listen` when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name).listen do |new_name|
        @name = new_name
      end
      person.name = new_name
      @name.should == new_name
    end

    it "should call multiple listeners when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name).listen do |new_name|
        @name1 = new_name
      end.listen do |new_name|
        @name2 = new_name
      end
      person.name = new_name
      @name1.should == new_name
      @name2.should == new_name
    end

  end

end
