# encoding: utf-8
module LogStash module Metrics
  class MonitoredSizeQueue
    attr_reader :queue, :counter, :meter_in, :meter_out

    def initialize(queue, metrics, name = "default")
      @queue = queue
      @counter = metrics.counter("size_queue.#{name}")
      @meter_in = metrics.meter("size_queue.#{name}.in")
      @meter_out = metrics.meter("size_queue.#{name}.out")
    end

    def push(item)
      queue << item
      counter.inc
      meter_in.mark
    end
    alias_method :enq, :push
    alias_method :<<, :push

    def pop
      counter.dec
      meter_out.mark
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
