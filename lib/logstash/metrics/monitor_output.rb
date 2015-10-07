# encoding: utf-8
module LogStash
  module Metrics
    class MonitorOutput
      attr_reader :queue, :meter

      def initialize(queue, metrics, name)
        @queue = queue
        @metric = metrics
        @name = name
        @meter = metrics.meter("outputs.#{name}")
      end

      def push(item)
        meter.mark 
        queue << item
      end
      alias_method :enq, :push
      alias_method :<<, :push

      def pop
        queue.pop
      end

      alias_method :deq, :pop
      alias_method :shift, :pop

      def size
        queue.size
      end
    end
  end
end
