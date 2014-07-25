require "spec_helper"

class TestScheduledJob
end

describe "Threasy::Schedule" do

  describe "#add" do
    let(:job){ double("job") }
    let(:schedule){ Threasy::Schedule.instance }

    it "should allow a job to be processed after specified delay" do
      expect(job).to receive(:perform)
      schedule.add(job, in: 0.1)
      sleep 0.2
    end

    it "should allow a job to be processed at the specified time" do
      expect(job).to receive(:perform)
      schedule.add(job, at: Time.now + 0.1)
      sleep 0.2
    end

    it "should allow a job to be repeated at the specified interval" do
      expect(job).to receive(:perform).at_least(:twice)
      schedule.add(job, every: 0.1, in: 0.1)
      sleep 0.3
    end

    it "should allow blocks to be processed on schedule" do
      i = 0
      schedule.add(in: 0.1){ i += 1 }
      expect(i).to eq(0)
      sleep 0.2
      expect(i).to eq(1)
    end

    it "should allow string expressions to be processed on schedule" do
      expect(TestScheduledJob).to receive(:perform)
      schedule.add("TestScheduledJob", in: 0.1)
      sleep 0.2
    end

    it "should default first run to now + every_interval" do
      expect(job).to receive(:perform).at_least(:twice)
      schedule.add(job, every: 0.1)
      sleep 0.3
    end

    it "should be possible to remove a job from the schedule" do
      expect(job).to receive(:perform).at_least(:once).at_most(:twice)
      entry = schedule.add(job, every: 0.1)
      sleep 0.2
      entry.remove
      sleep 0.2
    end
  end

  after :each do
    schedule.clear
  end

end
