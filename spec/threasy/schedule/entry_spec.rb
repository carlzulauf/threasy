describe Threasy::Schedule::Entry do
  let(:work) { double("work") }
  let(:job)  { double("work") }
  let(:hour) { 60 * 60 }

  subject { Threasy::Schedule::Entry }

  describe "#work!" do
    it "should execute a one-time job long after its due" do
      expect(work).to receive(:enqueue).with(job)
      entry = subject.new(job, work: work, in: hour/2)
      Timecop.travel(Time.now + hour) { entry.work! }
    end

    it "should not execute a repeating job long after its due" do
      expect(work).not_to receive(:enqueue).with(job)
      entry = subject.new(job, work: work, in: hour/2, every: hour)
      Timecop.travel(Time.now + hour) { entry.work! }
    end
  end

end
