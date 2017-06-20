# encoding: utf-8
import org.logstash.pipeline.BaseProcessor

module LogStash module Pipelines
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
end end