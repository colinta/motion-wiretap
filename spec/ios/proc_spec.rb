describe MotionWiretap::WiretapProc do

  describe "monitoring when a job is done" do

    it "should have the `wiretap` method" do
      ->{
        Motion.wiretap(-> {})
      }.should.not.raise
    end

    it "should return a WiretapKvo object" do
      Motion.wiretap(-> {}).should.is_a MotionWiretap::Wiretap
      Motion.wiretap(-> {}).should.is_a MotionWiretap::WiretapProc
    end

    it "should run the block when a block is given" do
      @did_call = false
      @did_complete = false
      Motion.wiretap(-> do
        @did_call = true
      end) do
        @did_complete = true
      end

      @did_call.should == true
    end

    it "should call the `and_then` block when the operation is complete" do
      @did_call = false
      @did_complete = false
      Motion.wiretap(-> do
        @did_call = true
      end) do
        @did_complete = true
      end

      @did_complete.should == true
    end

    it "should NOT run the block when unless start is called when using `and_then` method" do
      @did_call = false
      @did_complete = false
      wiretap = Motion.wiretap(-> do
        @did_call = true
      end).and_then do
        @did_complete = true
      end

      @did_call.should == false
      wiretap.start
      @did_call.should == true
    end

    it "should accept a callback in the block" do
      @has_callback = nil
      Motion.wiretap(-> (callback) do
        @has_callback = callback
      end) do
      end

      @has_callback.should.not == nil
    end

    it "should send a change event when the callback is handed a value" do
      @vals = []
      Motion.wiretap(-> (callback) do
        callback.call(1)
        callback.call(2)
        callback.call(3)
      end).listen do |value|
        @vals << value
      end.and_then do
        @vals << :done
      end.start

      @vals.should == [1, 2, 3, :done]
    end

  end

end
