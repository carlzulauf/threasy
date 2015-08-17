describe "Threasy::Schedule" do
  let(:job){ double("job") }
  subject { Threasy.schedules }

  describe "#add" do
    it "should allow a job to be processed after specified delay" do
      async do |done|
        subject.add(-> { done.() }, in: 0.1)
      end
    end

    it "should allow a job to be processed at the specified time" do
      async do |done|
        subject.add(-> { done.() }, at: Time.now + 0.1)
      end
    end

    it "should allow a job to be repeated at the specified interval" do
      async do |done|
        repeats = 0
        subject.add(every: 0.1, in: 0.1) do
          repeats += 1
          done.() if repeats == 2
        end
      end
    end
  end

  describe "#remove" do
    it "should be possible to remove a job from the schedule" do
      entry = subject.add(job, every: 0.1)
      expect(subject).to receive(:remove_entry).with(entry)
      entry.remove
    end
  end

  context "when laptop suspends" do
    subject { Threasy::Schedule.new }
    let(:hour) { 60*60 }

    it "should recover in a few seconds when time suddenly jumps forward" do
      Threasy.config.max_sleep = 0.1
      async do |done|
        subject.add(-> { done.() }, in: hour + 1)
        Timecop.travel(Time.now + hour)
      end
      Timecop.return
    end

  end

end
