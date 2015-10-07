require 'slf4j-jars'
require 'multimeter'

# encoding: utf-8
module LogStash
  class MetricsCollector
    attr_reader :registry, :name

    def initialize(name)
      @registry = Multimeter.create_registry
      @name = name
      expose
    end
    
    # expose:
    # - JMX
    # - HTTP
    # - Pipeline
    def expose
      Multimeter.jmx(registry, domain: name)
    end

    def self.create(name = "default")
      metrics = LogStash::MetricsCollector.new(name)
      metrics.registry
    end
  end
end
