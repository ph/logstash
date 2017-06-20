# encoding: utf-8
require "logstash/pipelines/base_processor"

module LogStash module Pipelines
  class FilterProcessor < BaseProcessor
    include org.logstash.pipeline.FilterProcessor

    def process(events)
      @plugin.multi_filter(events)
    end
  end
end end