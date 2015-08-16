class TestJob
end

describe "Threasy::Work" do
  before :each do
    @work = Threasy::Work.new
  end

  describe "#enqueue" do
    it "should have a method for enqueing" do
      expect(@work.respond_to?(:enqueue)).to eq(true)
    end

    it "should allow a job object to be enqueued and worked" do
      job = double("job")
      expect(job).to receive(:perform).once
      @work.enqueue job
      sleep 0.1
    end

    it "should allow a job block to be enqueued and worked" do
      i = 0
      @work.enqueue do
        sleep 0.1
        i += 1
      end
      expect(i).to eq(0)
      sleep 0.2
      expect(i).to eq(1)
    end

    it "should allow a string expression to be enqueued and worked" do
      expect(TestJob).to receive(:perform).once
      @work.enqueue "TestJob"
      sleep 0.1
    end
  end
end
