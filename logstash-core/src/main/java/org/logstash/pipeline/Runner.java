package org.logstash.pipeline;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;

public class Runner {
    private static final Logger logger = LogManager.getLogger(Event.class);

    private Execution execution;

    public Runner(Execution execution) {
        this.execution = execution;
    }

    public Runner() {

    }

    public boolean isRunning() {
        return true;
    }
    public void stop() {}
    public void start() {}
}
