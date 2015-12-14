# encoding: utf-8
require "logstash/instrument/snapshot"
require "logstash/instrument/metric_store"
require "logstash/util/loggable"
require "concurrent/map"
require "observer"
require "singleton"
require "thread"

module LogStash module Instrument
  # The Collector singleton is the single point of reference for all
  # the metrics collection inside logstash, the metrics library will make
  # direct calls to this class.
  #
  # This class is an observable responsable of periodically emitting view of the system
  # to other components like the internal metrics pipelines.
  class Collector
    include LogStash::Util::Loggable
    include Observable
    include Singleton

    SNAPSHOT_ROTATION_TIME = 1 # seconds

    def initialize
      @metric_store = MetricStore.new
    end

    # The metric library will call this unique interface
    # its the job of the collector to update the store with new metric
    # of update the metric
    #
    # If there is a problem with the key or the type of metric we will record an error 
    # but we wont stop processing events, theses errors are not considered fatal.
    # 
    def push(*args)
      namespaces_path, key, type, other = args

      begin
        metric = @metric_store.fetch_or_store(namespaces_path, key) { concrete_class(type).new(namespaces_path, key) }
        metric.execute(*other)
        changed
      rescue MetricStore::ConcurrentMapExpectedError => e
        logger.error("Collector: Cannot record metric", :exception => e)
      rescue NameError => e
        logger.error("Collector: Cannot create concrete class for this metric type", :type => type, :namespaces_path => namespaces_path, :key => key, :stacktrace => e.backtrace)
      end
    end

    def update(time, result, exception)
    end

    private
    # Use the string to generate a concrete class for this metrics
    # 
    # @param [String] The name of the class
    # @raise
    def concrete_class(type)
      LogStash::Instrument::MetricType.const_get(type.capitalize)
    end
  end
end; end
