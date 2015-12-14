# encoding: utf-8
require "logstash/instrument/metric_store"
require "logstash/instrument/metric_type/counter"

describe LogStash::Instrument::MetricStore do
  let(:namespaces) { [ :root, :pipelines, :pipeline_01 ] } 
  let(:key) { :events_in }
  let(:counter) { LogStash::Instrument::MetricType::Counter.new(key) }

  context "when the metric object doesn't exist" do
    it "store the object" do
      expect(subject.fetch_or_store(namespaces, key, counter)).to eq(counter)
    end
  end

  context "when the metric object exist in the namespace"  do
    let(:new_counter) { LogStash::Instrument::MetricType::Counter.new(key) }

    before do
      subject.fetch_or_store(namespaces, key, counter)
    end

    it "return the object" do
      expect(subject.fetch_or_store(namespaces, key, new_counter)).to eq(counter)
    end
  end

  context "when the namespace end node isn't a map" do
    let(:conflicting_namespaces) { [:root, :pipelines, :pipeline_01, :events_in] }

    before do
      subject.fetch_or_store(namespaces, key, counter)
    end

    it "raise an exception" do
      expect { subject.fetch_or_store(conflicting_namespaces, :new_key, counter) }.to raise_error(LogStash::Instrument::MetricStore::ConcurrentMapExpectedError)
    end
  end

  context "when retrieving metrics" do
  end
end
