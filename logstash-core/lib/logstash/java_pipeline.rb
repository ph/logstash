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
require "forwardable"

import "org.logstash.pipeline.Runner"
import "org.logstash.pipeline.Builder"
import "org.logstash.queue.Batch"
import "org.logstash.queue.ReadClient"
import "org.logstash.queue.WriteClient"
import "org.logstash.pipeline.BaseProcessor"

module LogStash
  class RubyExecution
    def filter(events)
    end

    def outputs(events)
    end

    private
  end

  class PluginFactory
    include org.logstash.pipeline.PluginFactory

    def initialize(agent = nil, dlq_writer = nil, metric = nil)
      @metric = metric
      @agent = agent
      @dlq_writer = dlq_writer
    end

    def create(plugin_type, name, settings = {})
      # use NullMetric if called in the BasePipeline context otherwise use the @metric value
      metric = @metric || Instrument::NullMetric.new

      pipeline_scoped_metric = metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :plugins])
      # Scope plugins of type 'input' to 'inputs'
      type_scoped_metric = pipeline_scoped_metric.namespace("#{plugin_type}s".to_sym)

      klass = Plugin.lookup(plugin_type, name)

      execution_context = ExecutionContext.new(self, @agent, id, klass.config_name, @dlq_writer)

      if plugin_type == "output"
        output_plugin = OutputDelegator.new(@logger, klass, type_scoped_metric, execution_context, OutputDelegatorStrategyRegistry.instance, args)
        OutputProcessor.new(output_plugin)
      elsif plugin_type == "filter"
        filter_plugin = FilterDelegator.new(@logger, klass, type_scoped_metric, execution_context, args)
        FilterProcessor.new(filter_plugin)
      else # input
        input_plugin = klass.new(args)
        scoped_metric = type_scoped_metric.namespace(id.to_sym)
        scoped_metric.gauge(:name, input_plugin.config_name)
        input_plugin.metric = scoped_metric
        input_plugin.execution_context = execution_context
        InputProcessor.new(input_plugin)
      end
    end
  end

  # TODO(ph): This might not be necessary but lets add a level of indirection between the java/ruby code
  # I don't want the plugin class to have a java interface yet, so theses class will proxy the calls between java
  # and the ruby world on a strict/simple interface
  class BaseProcessor
    include org.logstash.pipeline.BaseProcessor

    def initialize(plugin_instance)
      @plugin = plugin_instance
    end

    def register
      @plugin.register
    end

    def close
      @plugin.close
    end
  end

  class InputProcessor < BaseProcessor
    include org.logstash.pipeline.InputProcessor

    def run(queue)
      @plugin.run(queue)
    end
  end

  class FilterProcessor < BaseProcessor
    include org.logstash.pipeline.FilterProcessor

    def process(events)
      @plugin.multi_filter(events)
    end
  end

  class OutputProcessor < BaseProcessor
    include org.logstash.pipeline.OutputProcessor

    def process(events)
      @plugin.multi_receive(events)
    end
  end

  class JavaPipeline
    include LogStash::Util::Loggable

    def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
      # TODO:
      #
      # - [ ] We need to validate the ID in the graph to make sure they are unique when user are defining there own IDs.
      # - [ ] Batch size is a properties of the queue reader, not a concern of the runner of the plugin reading off the queue

      @settings = pipeline_config.settings
      @pipeline_config = pipeline_config


      # Add a plugin factory to replace `def plugin`, writing in the ruby world but with a java interface
      # Add an interface to be able to use the Ruby Execution
      @queue = LogStash::QueueFactory.create(@settings)

      pipeline_ir = compile_ir(pipeline_config.config_string)

      @pipeline = org.logstash.pipeline.Builder.new(pipeline_ir)
                      .pipelineId(@pipeline_config.pipeline_id)
                      .workers(@settings.get("pipeline.workers"))
                      .pluginFactory(PluginFactory.new)
                      .writeClient(@queue.write_client)
                      .readClient(@queue.read_client)
                      .build()

      # I think the runner should not really care if its an inputs or an outputs
      # this might complicate things because shutdown order is important
    end

    def running?
      @pipeline.isRunning()
    end

    def system?
      @settings.get("pipeline.system")
    end

    def pipeline_id
      @pipeline_config.pipeline_id
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

    private
    def compile_ir(config_string)
      source_with_metadata = SourceWithMetadata.new("str", "pipeline", 0, 0, self.config_str)
      LogStash::Compiler.compile_sources(source_with_metadata)
    end
  end
end
