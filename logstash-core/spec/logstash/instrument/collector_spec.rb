# encoding: utf-8
require "logstash/instrument/collector"
require "spec_helper"

describe LogStash::Instrument::Collector do
  context ".snapshot_rotation_time" do
    let(:time) { 4 } # seconds

    it "returns a default value" do
      expect(LogStash::Instrument::Collector.snapshot_rotation_time).not_to be_nil
    end

    it "should allow to override the snapshot_rotation time" do
      LogStash::Instrument::Collector.snapshot_rotation_time = time
      expect(LogStash::Instrument::Collector.snapshot_rotation_time).to eq(time)
    end
  end
end

