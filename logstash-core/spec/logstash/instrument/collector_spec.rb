# encoding: utf-8
require "logstash/instrument/collector"
require "spec_helper"

describe LogStash::Instrument::Collector do
  # context ".snapshot_rotation_time" do
  #   let(:time) { 4 } # seconds

  #   it "returns a default value" do
  #     expect(LogStash::Instrument::Collector.snapshot_rotation_time).not_to be_nil
  #   end

  #   it "should allow to override the snapshot_rotation time" do
  #     LogStash::Instrument::Collector.snapshot_rotation_time = time
  #     expect(LogStash::Instrument::Collector.snapshot_rotation_time).to eq(time)
  #   end
  # end
  #
  describe "#push" do
    let(:namespaces_path) { [:root, :pipelines, :pipelines01] }
    let(:key) { :my_key }

    context "when the `MetricType` exist" do
      [:counter].each do |type|
        it "store the metric of type #{type}" do
          LogStash::Instrument::Collector.instance.push(namespaces_path, key, type, :increment)
        end
      end
    end

    context "when the `MetricType` doesn't exist" do
      let(:wrong_type) { :donotexist }

      it "logs an error but dont crash" do
        expect(LogStash::Instrument::Collector.logger).to receive(:error)
          .with("Collector: Cannot create concrete class for this metric type",
        hash_including({ :type => wrong_type, :namespaces_path => namespaces_path }))
          LogStash::Instrument::Collector.instance.push(namespaces_path, key, wrong_type, :increment)
      end
    end

    context "when there is a conflict with the metric key" do
      let(:conflicting_namespaces) { [namespaces_path, key].flatten }

      it "logs an error but dont crash" do
        LogStash::Instrument::Collector.instance.push(namespaces_path, key, :counter, :increment)

        expect(LogStash::Instrument::Collector.logger).to receive(:error)
          .with("Collector: Cannot record metric", hash_including({ :exception => instance_of(LogStash::Instrument::MetricStore::ConcurrentMapExpectedError) }))
          LogStash::Instrument::Collector.instance.push(conflicting_namespaces, :random_key, :counter, :increment)
      end
    end
  end
end
