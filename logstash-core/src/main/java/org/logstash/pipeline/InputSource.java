package org.logstash.pipeline;

import org.logstash.config.ir.PipelineIR;
import org.logstash.config.ir.graph.PluginVertex;

public class InputSource {
    private final PipelineIR pipelineIR;
    private final PluginFactory pluginFactory;

    public InputSource(PipelineIR pipelineIR, PluginFactory pluginFactory) {
        this.pipelineIR = pipelineIR;
        this.pluginFactory = pluginFactory;
    }

    public int size() {
        return 1;
    }

    public Iterable<InputProcessor> getSources() {
        pipelineIR.getInputPluginVertices().stream()
                .collect(PluginVertex::getPluginDefinition)
                .map(pluginDefinition -> pluginFactory.create(pluginDefinition));
    }
}