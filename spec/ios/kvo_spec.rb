describe MotionWiretap::WiretapKvo do

  describe "monitoring changes to a model" do

    it "should have the `wiretap` method" do
      ->{
        w = Motion.wiretap(Person.new, :name)
        w.cancel!
      }.should.not.raise
    end

    it "should return a WiretapKvo object" do
      wiretap = Motion.wiretap(Person.new, :name)

      wiretap.should.is_a MotionWiretap::Wiretap
      wiretap.should.is_a MotionWiretap::WiretapKvo

      wiretap.cancel!
    end

    it "should call a block when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      wiretap = Motion.wiretap(person, :name) do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name
      wiretap.cancel!
    end

    it "should call a block only after a change" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      @times_called = 0
      wiretap = Motion.wiretap(person, :name) do |new_name|
        @times_called += 1
      end
      person.name = new_name
      @times_called.should == 1
      wiretap.cancel!
    end

    it "should call `listen` when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      wiretap = Motion.wiretap(person, :name).listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name
      wiretap.cancel!
    end

    it "should call multiple listeners when a change happens" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      wiretap = Motion.wiretap(person, :name).listen do |new_name|
        @new_name1 = new_name
      end.listen do |new_name|
        @new_name2 = new_name
      end
      person.name = new_name
      @new_name1.should == new_name
      @new_name2.should == new_name
      wiretap.cancel!
    end

    it "should not call listener when a filter returns false" do
      person = Person.new
      original_name = 'name 1'
      ok_name_1 = 'name 2'
      ok_name_2 = 'name 3'
      bad_name = 'ignore this'
      person.name = original_name
      @names = []
      wiretap = Motion.wiretap(person, :name).filter do |new_name|
        new_name != bad_name
      end.listen do |new_name|
        @names << new_name
      end
      person.name = ok_name_1
      person.name = bad_name
      person.name = ok_name_2
      person.name = bad_name
      @names.should == [ok_name_1, ok_name_2]
      wiretap.cancel!
    end

    it "should combine the value" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      wiretap = Motion.wiretap(person, :name).combine do |new_name|
        new_name.upcase
      end.listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name.upcase
      wiretap.cancel!
    end

    it "should map the value" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      wiretap = Motion.wiretap(person, :name).map do |new_name|
        new_name.upcase
      end.listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name.upcase
      wiretap.cancel!
    end

    it "should reduce the value" do
      person = Person.new
      original_name = 'name 1'
      new_name = 'name 2'
      person.name = original_name
      wiretap = Motion.wiretap(person, :name).reduce do |memo, new_name|
        new_name.upcase
      end.listen do |new_name|
        @new_name = new_name
      end
      person.name = new_name
      @new_name.should == new_name.upcase
      wiretap.cancel!
    end

  end

  it 'should bind two signals with `bind_to`' do
    p1 = Person.new
    p2 = Person.new
    wiretap_2 = Motion.wiretap(p2, :name)
    wiretap_1 = Motion.wiretap(p1, :name).bind_to(wiretap_2)
    p1.name = 'p1 name'
    p2.name = 'p2 name'
    p1.name.should == p2.name
    wiretap_1.cancel!
    wiretap_2.cancel!
  end

  it 'should bind two signals with `bind_to` and modify the value with `map`' do
    p1 = Person.new
    p2 = Person.new
    wiretap = Motion.wiretap(p1, :name).bind_to(Motion.wiretap(p2, :name).map { |value| value.upcase })
    p1.name = 'p1 name'
    p2.name = 'p2 name'
    p1.name.should == p2.name.upcase
    wiretap.cancel!
  end

end
