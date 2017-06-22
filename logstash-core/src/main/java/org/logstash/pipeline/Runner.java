package org.logstash.pipeline;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.queue.ReadClient;
import org.logstash.queue.WriteClient;
import org.logstash.util.LogstashThreadFactory;

import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Runner {
    private static final Logger logger = LogManager.getLogger(Event.class);

    private final String pipelineId;
    private final int workersCount;

    private final Execution execution;
    private final InputSource inputSource;

    private final ReadClient readClient;
    private final WriteClient writeClient;

    private final ExecutorService executorProducer;
    private final ExecutorService executorWorkers;

    private ArrayList producers = new ArrayList<InputWorker>();
    private ArrayList workers = new ArrayList<Worker>();


    // TODO(ph): State machine
    public Runner(String pipelineId, Execution execution, InputSource inputSource, int workersCount, ReadClient readClient, WriteClient writeClient) {
        this.pipelineId = pipelineId;
        this.execution = execution;
        this.inputSource = inputSource;
        this.workersCount = workersCount;
        this.readClient = readClient;
        this.writeClient = writeClient;

        this.executorProducer = Executors.newFixedThreadPool(inputSource.size(), new LogstashThreadFactory(pipelineId + ">"));
        this.executorWorkers = Executors.newFixedThreadPool(workersCount, new LogstashThreadFactory(pipelineId + "<"));
    }

    public boolean isRunning() {
        return true;
    }
    public void stop() {}
    public boolean start() {
        logger.info("Starting Pipeline: {}", pipelineId);

        createInputWorkers();
        createWorkers();
        startWorkers();
        startInputWorkers();

        logger.info("Pipeline started: {}", pipelineId);
    }

    private void startWorkers() {
        logger.debug("Starting workers, count: {}", workersCount);
        workers.forEach( worker -> executorWorkers.submit((Runnable) worker));
    }

    private void startInputWorkers() {
        logger.debug("Starting input workers, count: {}", producers.size());
        producers.forEach(producer -> executorProducer.submit((Runnable) producer));
    }


    private void createWorkers() {
        logger.debug("Creating workers");

        for(int i = 0; i < workersCount; i++) {
            workers.add(new Worker(execution, readClient, i + 1));
        }
    }

    private void createInputWorkers() {
        logger.debug("Creating input workers");
        inputSource.getSources().forEach(input -> producers.add(new InputWorker(input, writeClient)));
    }

    public String getPipelineId() {
        return pipelineId;
    }

    public int getWorkersCount() {
        return workersCount;
    }
}