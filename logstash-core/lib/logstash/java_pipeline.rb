# encoding: utf-8
require "thread"
require "stud/interval"
require "concurrent"
require "logstash/namespace"
require "logstash/errors"
require "logstash-core/logstash-core"
require "logstash/event"
require "logstash/config/file"
require "logstash/filters/base"
require "logstash/inputs/base"
require "logstash/outputs/base"
require "logstash/shutdown_watcher"
require "logstash/pipeline_reporter"
require "logstash/instrument/metric"
require "logstash/instrument/namespaced_metric"
require "logstash/instrument/null_metric"
require "logstash/instrument/namespaced_null_metric"
require "logstash/instrument/collector"
require "logstash/instrument/wrapped_write_client"
require "logstash/util/dead_letter_queue_manager"
require "logstash/output_delegator"
require "logstash/filter_delegator"
require "logstash/queue_factory"
require "logstash/compiler"
require "logstash/execution_context"
require "logstash/pipelines/plugin_factory"
require "logstash/pipelines/base_processor"
require "logstash/pipelines/input_processor"
require "logstash/pipelines/filter_processor"
require "logstash/pipelines/output_processor"
require "forwardable"

import org.logstash.pipeline.Runner
import org.logstash.pipeline.Builder
import org.logstash.queue.Batch
import org.logstash.queue.ReadClient
import org.logstash.queue.WriteClient

module LogStash
  # Usercase: input run raise exception
  #
  # current behavior:
  #
  # - If Logstash is shutting down, we ignore the exception
  # - We sleep 1s, and we call run(queue) again

  # Usercase: Filter worker raise exception
  #
  # current behavior:
  # - We log and the thread dies

  # Usecase: Outputs workers raise an exception
  #
  # current behavior:
  # - we don't log anything
  # - the thread crash


  # init
  # starting
  # started
  # stopping
  # stopped
  # crashed

  class JavaPipeline
    include LogStash::Util::Loggable

    def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
      # TODO:
      #
      # - [ ] We need to validate the ID in the graph to make sure they are unique when user are defining there own IDs.
      # - [ ] Batch size is a properties of the queue reader, not a concern of the runner of the plugin reading off the queue
      # - [ ] Add a plugin factory to create the instance in the ruby world
      # - [ ] Max inflight message bootstrap check per pipeline/visitor settings
      # - [ ] define states of the pipeline
      # - [ ] add Log4j context for logging
      # - [ ] Make sure out executor threads are named correctly
      # - [ ] Clarify multi_filter, vs filter, I believe we never work on batch..
      # - [ ] The queue can have signal too.
      # - [ ] for flushing we will need to still have 2 methods, 1 for outputs and 1 for filters
      # - [ ] Add a scheduled task thread poll http://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ForkJoinPool.html#commonPool--
      #
      @settings = pipeline_config.settings
      @pipeline_config = pipeline_config

      @queue = LogStash::QueueFactory.create(@settings)

      pipeline_ir = compile_ir(pipeline_config.config_string)

      @pipeline = org.logstash.pipeline.Builder.new(pipeline_ir)
                      .pipelineId(@pipeline_config.pipeline_id)
                      .workers(@settings.get("pipeline.workers"))
                      .pluginFactory(LogStash::Pipelines::PluginFactory.new(@pipeline_config.pipeline_id))
                      .writeClient(@queue.write_client)
                      .readClient(@queue.read_client)
                      .build()
    end

    def running?
      @pipeline.isRunning()
    end

    def system?
      @settings.get("pipeline.system")
    end

    def pipeline_id
      @pipeline.getPipelineId();
    end

    # Have to decide what to do with them
    def reloadable?
      configured_as_reloadable? && reloadable_plugins?
    end

    # TODO(ph): Remove this
    def config_str
      @pipeline_config.config_string
    end

    def config_hash
      @pipeline_config.config_hash
    end

    def configured_as_reloadable?
      @settings.get("pipeline.reloadable")
    end

    def reloadable_plugins?
      non_reloadable_plugins.empty?
    end

    def non_reloadable_plugins
      []
    end

    # TODO(ph): update this?, replace with inspect and a custom inspect implementation
    def thread
      "Need to be changed"
    end

    def stop
      @pipeline.stop
    end

    # Notes: Currently the action is using the return value know if we successfully started the
    # pipeline.
    def start
      @pipeline.start
    end

    def shutdown(&before_stop)
    end

    private
    def compile_ir(config_string)
      source_with_metadata = SourceWithMetadata.new("str", "pipeline", 0, 0, self.config_str)
      LogStash::Compiler.compile_sources(source_with_metadata)
    end
  end
end
