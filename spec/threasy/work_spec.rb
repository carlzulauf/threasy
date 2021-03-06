class TestJob
  def initialize(resolver)
    @resolver = resolver
  end

  def perform(*args)
    @resolver.()
  end
end

describe "Threasy::Work" do
  subject { Threasy::Work.new }
  after(:each) { subject.clear }

  describe "#enqueue" do
    it "should have a method for enqueing" do
      expect(subject.respond_to?(:enqueue)).to eq(true)
    end

    it "should allow a job object to be enqueued and worked" do
      async do |done|
        subject.enqueue TestJob.new(done)
      end
    end

    it "should allow a job block to be enqueued and worked" do
      async do |done|
        subject.enqueue { done.() }
      end
    end

    it "should allow a string expression to be enqueued and worked" do
      async do |done|
        expect(TestJob).to receive(:perform).once
        subject.enqueue "TestJob"
        subject.enqueue { done.() }
      end
    end

    it "should pass optional arguments onto job" do
      async do |done|
        args = [:foo, :bar]
        job = proc do |*a|
          expect(a).to eq(args)
          done.()
        end
        subject.enqueue job, *args
      end
    end
  end
end
