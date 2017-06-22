package org.logstash.pipeline;

import org.logstash.queue.WriteClient;

public class InputWorker implements Runnable {
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
}
