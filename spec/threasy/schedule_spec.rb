require "spec_helper"

describe "Threasy::Schedule" do

  before :each do
    @schedule = Threasy::Schedule.instance
  end

  describe "#add" do
    it "should allow a job to be processed after specified delay" do
      job = double("job")
      expect(job).to receive(:perform)
      @schedule.add(job, in: 0.5)
      sleep 1
    end

    it "should allow a job to be processed at the specified time" do
      job = double("job")
      expect(job).to receive(:perform)
      @schedule.add(job, at: Time.now + 1)
      sleep 2
    end

    it "should allow a job to be repeated at the specified interval" do
      job = double("job")
      expect(job).to receive(:perform).at_least(:twice)
      @schedule.add(job, every: 1)
      sleep 3
    end

    it "should allow blocks to be processed on schedule" do
      job = double("job")
      i = 0
      @schedule.add(:in => 0.5){ i += 1 }
      expect(i).to eq(0)
      sleep 1
      expect(i).to eq(1)
    end
  end

  after :each do
    @schedule.clear
  end

end
