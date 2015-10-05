# encoding: utf-8
module LogStash module Metrics
  class MonitoredSizeQueue
    attr_reader :queue, :counter

    def initialize(queue, metrics, name = "default")
      @queue = queue
      @counter = metrics.counter("size_queue.#{name}")
    end

    def push(item)
      counter.inc
      queue << item
    end
    alias_method :enq, :push
    alias_method :<<, :push

    def pop
      counter.dec
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
