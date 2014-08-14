require "spec_helper"

class TestScheduledJob
end

def with_schedule(delay: nil, after: nil)
  schedule = Threasy::Schedule.instance
  yield schedule
  sleep delay if delay
  after.call if after
  schedule.clear
end

describe "Threasy::Schedule" do

  describe "#add" do
    let(:job){ double("job") }
    # let(:schedule){ Threasy::Schedule.instance }

    it "should allow a job to be processed after specified delay" do
      with_schedule(delay: 0.2) do |schedule|
        expect(Threasy).to receive(:enqueue).with(job)
        schedule.add(job, in: 0.1)
      end
    end

    it "should allow a job to be processed at the specified time" do
      with_schedule(delay: 0.2) do |schedule|
        expect(Threasy).to receive(:enqueue).with(job)
        schedule.add(job, at: Time.now + 0.1)
      end
    end

    it "should allow a job to be repeated at the specified interval" do
      with_schedule(delay: 0.3) do |schedule|
        expect(Threasy).to receive(:enqueue).with(job).at_least(:twice)
        schedule.add(job, every: 0.1, in: 0.1)
      end
    end

    it "should allow blocks to be processed on schedule" do
      i = 0
      with_schedule(delay: 0.2, after: ->{ expect(i).to eq(1) }) do |schedule|
        schedule.add(in: 0.1){ i += 1 }
        expect(i).to eq(0)
      end
    end

    it "should allow string expressions to be processed on schedule" do
      with_schedule(delay: 0.2) do |schedule|
        expect(TestScheduledJob).to receive(:perform)
        schedule.add("TestScheduledJob", in: 0.1)
      end
    end

    it "should default first run to now + every_interval" do
      with_schedule(delay: 0.3) do |schedule|
        expect(Threasy).to receive(:enqueue).with(job).at_least(:twice)
        schedule.add(job, every: 0.1)
      end
    end

    it "should be possible to remove a job from the schedule" do
      schedule = Threasy::Schedule.instance
      expect(Threasy).to receive(:enqueue).with(job).at_least(:once).at_most(:twice)
      entry = schedule.add(job, every: 0.1)
      sleep 0.2
      entry.remove
      sleep 0.2
      schedule.clear
    end
  end

end
