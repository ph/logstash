# encoding: utf-8
import org.logstash.pipeline.PluginFactory

module LogStash module Pipelines
  class PluginFactory
    include org.logstash.pipeline.PluginFactory

    attr_reader :pipeline_id

    def initialize(pipeline_id, agent = nil, dlq_writer = nil, metric = nil)
      @pipeline_id = pipeline_id
      @metric = metric
      @agent = agent
      @dlq_writer = dlq_writer
    end

    def create(plugin_definition)
      name = plugin_definition.getName()
      id = plugin_definition.getId()
      plugin_type = plugin_definition.getType().toString().downcase;
      args = plugin_definition.getArguments()

      # use NullMetric if called in the BasePipeline context otherwise use the @metric value
      metric = @metric || Instrument::NullMetric.new

      pipeline_scoped_metric = metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :plugins])
      # Scope plugins of type 'input' to 'inputs'
      type_scoped_metric = pipeline_scoped_metric.namespace("#{plugin_type}s".to_sym)

      klass = Plugin.lookup(plugin_type, name)

      execution_context = ExecutionContext.new(self, @agent, id, klass.config_name, @dlq_writer)


      if plugin_type == "output"
        output_plugin = OutputDelegator.new(@logger, klass, type_scoped_metric, execution_context, OutputDelegatorStrategyRegistry.instance, args)
        LogStash::Pipelines::InputProcessorr.new(output_plugin)
      elsif plugin_type == "filter"
        filter_plugin = FilterDelegator.new(@logger, klass, type_scoped_metric, execution_context, args)
        LogStash::Pipelines::InputProcessorr.new(filter_plugin)
      else # input
        input_plugin = klass.new(args)
        scoped_metric = type_scoped_metric.namespace(id.to_sym)
        scoped_metric.gauge(:name, input_plugin.config_name)
        input_plugin.metric = scoped_metric
        input_plugin.execution_context = execution_context

        LogStash::Pipelines::InputProcessor.new(input_plugin)
      end
    end
  end
end end