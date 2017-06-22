package org.logstash.pipeline;

import org.logstash.Event;

import java.util.List;

public interface Execution {
    public void process(Object Batch);
    public void process(List<Event> events);
    public void stop();
    public boolean isStopped();
    public void flush();
}
