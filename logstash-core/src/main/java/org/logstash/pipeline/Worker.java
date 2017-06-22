package org.logstash.pipeline;

import org.logstash.queue.ReadClient;
import org.logstash.util.LogstashWorker;

/**
 * Created by ph on 2017-06-20.
 */
public class Worker implements Runnable, LogstashWorker {
    private final Execution execution;
    private final ReadClient readClient;
    private final int workerNumber;

    public Worker(Execution execution, ReadClient readClient, int workerNumber) {
        this.execution = execution;
        this.readClient = readClient;
        this.workerNumber = workerNumber;
    }

    @Override
    public void run() {
       while(true) {
          execution.process(readClient.readBatch());
       }
    }

    @Override
    public String getWorkerName() {
        return "workers-" + workerNumber;
    }
}
