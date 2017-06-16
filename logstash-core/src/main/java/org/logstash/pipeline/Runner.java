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

public class Runner {
    private static final Logger logger = LogManager.getLogger(Event.class);

    private final String pipelineId;
    private final PipelineIR pipelineIR;
    private final PluginFactory pluginFactory;
    private final int workersCount;
    private final ReadClient readClient;
    private final WriteClient writeClient;

    private List<InputProcessor> inputs = new ArrayList<>();
    private List<FilterProcessor> filters = new ArrayList<>();
    private List<OutputProcessor> outputs = new ArrayList<>();

    public Runner(String pipelineId, PipelineIR pipelineIR, PluginFactory pluginFactory, int workersCount, ReadClient readClient, WriteClient writeClient) {
        this.pipelineId = pipelineId;
        this.pipelineIR = pipelineIR;
        this.pluginFactory = pluginFactory;
        this.workersCount = workersCount;
        this.readClient = readClient;
        this.writeClient = writeClient;
    }

    private void createInputs() {
        pipelineIR.getInputPluginVertices().forEach(vertex -> inputs.add((InputProcessor) createPlugin(vertex.getPluginDefinition())));
    }

    private void createFilters() {
      //  pipelineIR.getFilterPluginVertices(pluginVertex -> filters.add(createPlugin(pluginVertex.getPluginDefinition())));
    }

    private void createOutputs() {
   //     pipelineIR.getOutputPluginVertices(pluginVertex -> filters.add(createPlugin(pluginVertex.getPluginDefinition())));
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
       createPlugins();
       return true;
    }

    public String getPipelineId() {
        return pipelineId;
    }

    public int getWorkersCount() {
        return workersCount;
    }
}
