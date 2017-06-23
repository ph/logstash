package org.logstash.pipeline;

import jdk.internal.util.xml.impl.Input;
import org.logstash.config.ir.PipelineIR;
import org.logstash.config.ir.graph.PluginVertex;

import java.util.List;
import java.util.stream.Collectors;

public class InputSource {
    private final PipelineIR pipelineIR;
    private final PluginFactory pluginFactory;
    private final List<InputProcessor> inputSources;

    public InputSource(PipelineIR pipelineIR, PluginFactory pluginFactory) {
        this.pipelineIR = pipelineIR;
        this.pluginFactory = pluginFactory;
        this.inputSources = getSources();
    }

    public int size() {
        return 1;
    }

    public Iterable<InputProcessor> sources() {
        return inputSources;
    }

    private List<InputProcessor> getSources() {
        return pipelineIR.getInputPluginVertices()
                .stream()
                .map(pluginVertex -> (InputProcessor) pluginFactory.create(pluginVertex.getPluginDefinition()))
                .collect(Collectors.toList());
    }
}