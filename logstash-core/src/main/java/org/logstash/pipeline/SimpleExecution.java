package org.logstash.pipeline;

import org.logstash.Event;
import org.logstash.config.ir.PipelineIR;

import java.util.List;

public class SimpleExecution implements Execution {
    private final PluginFactory publicFactory;
    private final PipelineIR ir;
    private boolean stopped = false;

    public SimpleExecution(PluginFactory pluginFactory, PipelineIR ir) {
        this.publicFactory = pluginFactory;
        this.ir = ir;
        //this.processors = createPlugins();
        // Create / register plugin
        // compile the execution

    }


    @Override
    public void process(Object batch) {
        // defensively we cannot reuse an execution that was closed.
        if(isStopped()) {
            // Throw stopped execution
        }
        // get events call process with events

    }

    @Override
    public void process(List<Event> events) {

    }

    @Override
    public void stop() {
        stopped = true;
        // close filter
        // close output
    }

    @Override
    public boolean isStopped() {
        return false;
    }

    @Override
    public void flush() {
    }
}