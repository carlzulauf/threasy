describe "Threasy::Schedule" do
  let(:job){ double("job") }
  let(:work){ double("work") }
  subject{ Threasy::Schedule.new(work) }

  describe "#add" do
    it "should allow a job to be processed after specified delay" do
      expect(work).to receive(:enqueue).with(job)
      subject.add(job, in: 0.1)
      sleep 0.3
    end

    it "should allow a job to be processed at the specified time" do
      expect(work).to receive(:enqueue).with(job)
      subject.add(job, at: Time.now + 0.1)
      sleep 0.3
    end

    it "should allow a job to be repeated at the specified interval" do
      expect(work).to receive(:enqueue).with(job).at_least(:twice)
      subject.add(job, every: 0.1, in: 0.1)
      sleep 0.5
    end

    it "should allow blocks to be processed on schedule" do
      block_job = ->{ 1 + 1 }
      expect(work).to receive(:enqueue).with(block_job)
      subject.add(in: 0.1, &block_job)
      sleep 0.3
    end

    it "should allow string expressions to be processed on schedule" do
      expect(work).to receive(:enqueue).with("TestScheduledJob")
      subject.add("TestScheduledJob", in: 0.1)
      sleep 0.3
    end

    it "should default first run to now + every_interval" do
      expect(work).to receive(:enqueue).with(job).at_least(:twice)
      subject.add(job, every: 0.1)
      sleep 0.5
    end
  end

  describe "#remove" do
    it "should be possible to remove a job from the schedule" do
      expect(work).to receive(:enqueue).with(job).at_least(:once)

      entry = subject.add(job, every: 0.1)
      sleep 0.3

      entry.remove

      expect(work).not_to receive(:enqueue)
      sleep 0.3
    end
  end

  context "when laptop suspends" do
    subject{ Threasy::Schedule.new }
    let(:hour) { 60*60 }

    it "should recover in a few seconds when time suddenly jumps forward" do
      Threasy.config.max_sleep = 0.1
      job_ran = false
      job = -> { job_ran = true }
      subject.add(in: hour + 1, &job)

      Timecop.travel(Time.now + hour) do
        Timeout.timeout(6) do
          loop { job_ran ? break : sleep(0.1) }
        end
      end
    end

  end

end
