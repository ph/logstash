package org.logstash.pipeline;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.config.ir.PipelineIR;
import org.logstash.queue.ReadClient;
import org.logstash.queue.WriteClient;

public class Runner {
    private static final Logger logger = LogManager.getLogger(Event.class);

    private Execution execution;

    public Runner(String pipelineId, PipelineIR pipelineIR, int workersCount, ReadClient readClient, WriteClient writeClient) {

    }

    public boolean isRunning() {
        return true;
    }
    public void stop() {}
    public boolean start() {
       return true;
    }
}
