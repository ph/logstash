# encoding: utf-8
require "forwardable"
import "org.logstash.pipeline.Runner"
import "org.logstash.pipeline.Builder"

module LogStash
  class RubyExecution
    def filter(events)
    end

    def outputs(events)
    end

    private
  end

  class JavaPipeline
    extend Forwardable

    include LogStash::Util::Loggable

    def_delegator :@pipeline, :start, :stop

    def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
      # Get LIR
      # Validate Plugins
      # Send LIR to Execution
      # Send execution to pipeline runner
      @settings = pipeline_config.settings
      @pipeline_config = pipeline_config


      # Add a plugin factory to replace `def plugin`, writing in the ruby world but with a java interface

      # Add an interface to be able to use the Ruby Execution
      @pipeline = new org.logstash.pipeline.Builder(compile_ir(pipeline_config.config_string))
                          .pipelineId(settings.get("pipeline.id"))
                          .batch(settings.get("pipeline.batch.size"))
                          .workers(settings.get("pipeline.workers"))
                          .build()
      #.pluginFactory()
      #.dlq()
      #.queue()
      # metrics ?? # will do that last


      # I think the runner should not really care if its an inputs or an outputs
      # this might complicate things because shutdown order is important

      # DLQ
      # Queue
      # Metrics
      # Agent
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

    private
    def compile_ir(config_string)
      source_with_metadata = SourceWithMetadata.new("str", "pipeline", 0, 0, self.config_str)
      LogStash::Compiler.compile_sources(source_with_metadata)
    end
  end
end
