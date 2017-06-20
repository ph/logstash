package org.logstash.pipeline;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.config.ir.PipelineIR;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.queue.ReadClient;
import org.logstash.queue.WriteClient;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Runner {
    private static final Logger logger = LogManager.getLogger(Event.class);

    private final String pipelineId;
    private final PipelineIR pipelineIR;
    private final PluginFactory pluginFactory;
    private final int workersCount;
    private final ReadClient readClient;
    private final WriteClient writeClient;

    private List<BaseProcessor> inputs = new ArrayList<>();
    private List<BaseProcessor> filters = new ArrayList<>();
    private List<BaseProcessor> outputs = new ArrayList<>();

    private final ExecutorService consumers;
    private final ExecutorService producers;
    // private final ExecutorService scheduledTasks;

    class InputWorker implements Runnable {
        private final WriteClient writeClient;
        private final InputProcessor inputProcessor;

        public InputWorker(InputProcessor inputProcessor, WriteClient writeClient) {
            this.inputProcessor = inputProcessor;
            this.writeClient = writeClient;
        }

        @Override
        public void run() {
            inputProcessor.process(writeClient);
        }

        public void shutdown() {}
    }

    class ProcessorWorker implements Runnable {
        private final ReadClient readClient;
        private final Execution execution;
        private volatile boolean running = true;


        public Worker(ReadClient readClient, Execution execution) {
            this.readClient = readClient;
            this.execution = execution;
        }

        @Override
        public void run() {
            // while not stopped read from queue
            // execute
            while(running) {
                Batch batch = readClient.readBatch();
                execution.execute(batch.getEvents);

                // do stuff
                // batch = queue.readBatch()
                // events = batch.getEvents()
                // execution.execution(events)
            }
        }

        public void shutdown() {
            running = false;
        }
    }

    public Runner(String pipelineId, PipelineIR pipelineIR, PluginFactory pluginFactory, int workersCount, ReadClient readClient, WriteClient writeClient) {
        this.pipelineId = pipelineId;
        this.pipelineIR = pipelineIR;
        this.pluginFactory = pluginFactory;
        this.workersCount = workersCount;
        this.readClient = readClient;
        this.writeClient = writeClient;

        createPlugins();

        this.consumers = Executors.newFixedThreadPool(workersCount);
    }

    private void createInputs() {
        pipelineIR.getInputPluginVertices().forEach(vertex -> inputs.add(createPlugin(vertex.getPluginDefinition())));
    }

    private void createFilters() {
        pipelineIR.getInputPluginVertices().forEach(vertex -> filters.add(createPlugin(vertex.getPluginDefinition())));
    }

    private void createOutputs() {
        pipelineIR.getInputPluginVertices().forEach(vertex -> outputs.add(createPlugin(vertex.getPluginDefinition())));
    }

    private void createPlugins() {
        createOutputs();
        createFilters();
        createInputs();
    }

    private BaseProcessor createPlugin(PluginDefinition pluginDefinition) {
        return pluginFactory.create(pluginDefinition);
    }

    public boolean isRunning() {
        return true;
    }
    public void stop() {}
    public boolean start() {
       return true;
    }

    public String getPipelineId() {
        return pipelineId;
    }

    public int getWorkersCount() {
        return workersCount;
    }
}