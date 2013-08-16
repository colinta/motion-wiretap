describe "Motion Wiretap" do

  describe "monitoring changes to a model" do

    it "should have the `wiretap` method" do
      ->{
        Person.new.wiretap(:name)
      }.should.not.raise
    end

    it "should return a WiretapKvo object" do
      Person.new.wiretap(:name).should.is_a MotionWiretap::Wiretap
      Person.new.wiretap(:name).should.is_a MotionWiretap::WiretapKvo
    end

    it "should call a block when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name) do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name
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
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name
    end

    it "should call multiple listeners when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name).listen do |new_name|
        @new_name1 = new_name
      end.listen do |new_name|
        @new_name2 = new_name
      end
      person.name = new_name
      @new_name1.should == new_name
      @new_name2.should == new_name
    end

    it "should not call listener when a filter returns false" do
      person = Person.new
      original_name = 'name 1'
      ok_name = 'name 2'
      bad_name = 'ignore this'
      person.name = original_name
      @names = []
      person.wiretap(:name).filter do |new_name|
        new_name != bad_name
      end.listen do |new_name|
        @names << new_name
      end
      person.name = ok_name
      person.name = bad_name
      @names.should == [ok_name]
    end

    it "should combine the value" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name).combine do |new_name|
        new_name.upcase
      end.listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name.upcase
    end

    it "should map the value" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name).map do |new_name|
        new_name.upcase
      end.listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name.upcase
    end

    it "should reduce the value" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      person.wiretap(:name).reduce do |memo, new_name|
        new_name.upcase
      end.listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name.upcase
    end

  end

  it 'should bind two signals with `bind_to`' do
    p1 = Person.new
    p2 = Person.new
    p1.wiretap(:name).bind_to(p2.wiretap(:name))
    p1.name = 'p1 name'
    p2.name = 'p2 name'
    p1.name.should == p2.name
  end

  it 'should bind two signals with `bind_to` and modify the value with `map`' do
    p1 = Person.new
    p2 = Person.new
    p1.wiretap(:name).bind_to(p2.wiretap(:name).map { |value| value.upcase })
    p1.name = 'p1 name'
    p2.name = 'p2 name'
    p1.name.should == p2.name.upcase
  end

end
