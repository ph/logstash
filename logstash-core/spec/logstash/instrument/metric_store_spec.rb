# encoding: utf-8
require "logstash/instrument/metric_store"
require "logstash/instrument/metric_type/counter"

describe LogStash::Instrument::MetricStore do
  let(:namespaces) { [ :root, :pipelines, :pipeline_01 ] } 
  let(:key) { :events_in }
  let(:counter) { LogStash::Instrument::MetricType::Counter.new(namespaces, key) }

  context "when the metric object doesn't exist" do
    it "store the object" do
      expect(subject.fetch_or_store(namespaces, key, counter)).to eq(counter)
    end

    it "support a block as argument" do
      expect(subject.fetch_or_store(namespaces, key) { counter }).to eq(counter)
    end
  end

  context "when the metric object exist in the namespace"  do
    let(:new_counter) { LogStash::Instrument::MetricType::Counter.new(namespaces, key) }

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

  describe "#to_event" do
    let(:metric_events) {
      [
        [[:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch"], :event_in, :increment],
        [[:node, :sashimi, :pipelines, :pipeline01, :plugins, :"logstash-output-elasticsearch"], :event_in, :increment],
        [[:node, :sashimi, :pipelines, :pipeline01], :processed_events, :increment],
      ]
    }

    before do
      # Lets add a few metrics in the store before trying to convert them
      metric_events.each do |namespaces, metric_key, action|
        metric = subject.fetch_or_store(namespaces, metric_key, LogStash::Instrument::MetricType::Counter.new(namespaces, key))
        metric.execute(action)
      end
    end

    it "converts all metric to `Logstash::Event`" do
      events = subject.to_events
      expect(events.size).to eq(2)
      events.each do |event|
        expect(event).to be_kind_of(LogStash::Event)
      end
    end
  end
end
