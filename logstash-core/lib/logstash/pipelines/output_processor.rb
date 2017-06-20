# encoding: utf-8
require "logstash/pipelines/base_processor"

module LogStash module Pipelines
  class OutputProcessor < BaseProcessor
    include org.logstash.pipeline.OutputProcessor

    def process(events)
      @plugin.multi_receive(events)
    end
  end
end end