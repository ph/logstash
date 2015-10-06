# encoding: utf-8
module LogStash
  class MetricsCollector
    attr_reader :registry

    def initialize(name)
      @registry = Multimeter.create_registry
      Multimeter.jmx(registry)
      # add custom reporter for our pipeline
    end

    def self.create(name = "default")
      metrics = LogStash::MetricsCollector.new(name)
      metrics.registry
    end
  end
end
