# encoding: utf-8
require "spec_helper"
require "logstash/pipeline"
require "logstash/pipeline_reporter"

#TODO: Figure out how to add more tests that actually cover inflight events
#This will require some janky multithreading stuff
describe LogStash::PipelineReporter do
  let(:generator_count) { 5 }
  let(:config) do
    "input { generator { count => #{generator_count} } } output { } "
  end
  let(:pipeline) { LogStash::Pipeline.new(config)}
  let(:reporter) { pipeline.reporter }

  before do
    @pre_snapshot = reporter.snapshot
    pipeline.run
    @post_snapshot = reporter.snapshot
  end

  describe "events filtered" do
    it "should start at zero" do
      expect(@pre_snapshot.events_filtered).to eql(0)
    end

    it "should end at the number of generated events" do
      expect(@post_snapshot.events_filtered).to eql(generator_count)
    end
  end

  describe "events consumed" do
    it "should start at zero" do
      expect(@pre_snapshot.events_consumed).to eql(0)
    end

    it "should end at the number of generated events" do
      expect(@post_snapshot.events_consumed).to eql(generator_count)
    end
  end

  describe "inflight count" do
    it "should be zero before running" do
      expect(@pre_snapshot.inflight_count).to eql(0)
    end

    it "should be zero after running" do
      expect(@post_snapshot.inflight_count).to eql(0)
    end
  end
end