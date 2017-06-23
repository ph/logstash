package org.logstash.pipeline;

import org.logstash.queue.WriteClient;
import org.logstash.util.LogstashWorker;

public class InputWorker implements Runnable, LogstashWorker {
    private final InputProcessor input;
    private final WriteClient writeClient;

    public InputWorker(InputProcessor input, WriteClient writeClient) {
        this.input = input;
        this.writeClient = writeClient;
    }

    @Override
    public void run() {
        // TODO: better handling of what is going wrong / catching of exection and restarting
        while(true) {
           input.process(writeClient);
        }
    }

    @Override
    public String getWorkerName() {
        return "input plugin";
    }
}
