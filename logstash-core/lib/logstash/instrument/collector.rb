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

      start_periodic_snapshotting
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
        changed # we had changes coming in so we can notify the observers
      rescue MetricStore::ConcurrentMapExpectedError => e
        logger.error("Collector: Cannot record metric", :exception => e)
      rescue NameError => e
        logger.error("Collector: Cannot create concrete class for this metric type", :type => type, :namespaces_path => namespaces_path, :key => key, :stacktrace => e.backtrace)
      end
    end

    # Monitor the `Concurrent::TimerTask` this update is triggered on every successful or not
    # run of the task, this method will record the execution in the log
    #
    # @param [Time] Time of execution
    # @param [result] Result of the execution
    # @param [Exception] Exception
    def update(time_of_execution, result, exception)
      return true if exception.nil?
      logger.error("Collector: Something went wrong went sending data to the observers", 
                   :execution_time => time_of_execution,
                   :result => result,
                   :exception => exception)
    end

    private
    # Use the string to generate a concrete class for this metrics
    # 
    # @param [String] The name of the class
    # @raise
    def concrete_class(type)
      LogStash::Instrument::MetricType.const_get(type.capitalize)
    end

    # Configure and start the periodic task for snapshotting the `MetricStore`
    def start_periodic_snapshotting
      @snapshot_task = Concurrent::Task.new { publish_snapshot }
      @snapshot_task.interval = self.class.snapshot_time
      @snapshot_task.add_observer(self)
      @snapshot_task.execute
    end

    # Create a snapshot of the MetricStore and send it to to the registered observers
    def publish_snapshot
      time_created = Concurrent.monotonic
      logger.debug("Collector: Sending snapshot to observers", :created_at => created_at) if logger.debug?
      notify_observers(time_created, @metric_store.dup)
    end
  end
end; end
