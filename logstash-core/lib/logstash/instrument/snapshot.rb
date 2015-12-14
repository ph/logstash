# encoding: utf-8
require "logstash/instrument/metric_type/counter"
require "logstash/util/loggable"
require "logstash/event"

module LogStash module Instrument
  class Snapshot
    include LogStash::Util::Loggable
   
    def initialize
      @metrics = Concurrent::Map.new
    end

    def push(*args)
      # A few examples namespace
      # [root, pipeline-1]
      # [root, pipeline-1, output, elasticsearch]
      # [root, pipeline-1, filter, mutate]
      #
      # The namespace are actually tags on the data itself in the elastisearch document?
      # we might need something more granular
      #
      # [
      #   :pipeline => pipeline,
      #   :plugin => logstash-filter-elasticsearch
      # ]


      namespace, key, type, _ = args
      # fetch_namespace(.fetch_or_store(key)
      # metric = @metrics.fetch_or_store([namespace, key].join('-'), concrete_class(type, key))
      # metric.execute(*args)
    end

    def concrete_class(type, key)
      # TODO, benchmark, I think this is faster than using constantize
      case type
      when :counter then MetricType::Counter.new(key)
      end
    end

    def size
      @metrics.size
    end

    def to_event
      LogStash::Event.new({ "message" => "HELLO MEtrics",
                            "size" => @metrics.size })
    end

    def inspect
      "#{self.class.name} - metrics: #{@metrics.values.map(&:inspect)}"
    end
  end
end; end
