# encoding: utf-8
require "logstash/pipelines/base_processor"

module LogStash module Pipelines
  class InputProcessor < BaseProcessor
    include org.logstash.pipeline.InputProcessor

    def run(queue)
      @plugin.run(queue)
    end
  end
end end