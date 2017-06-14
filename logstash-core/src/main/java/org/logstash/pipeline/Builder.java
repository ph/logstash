package org.logstash.pipeline;

import org.logstash.config.ir.PipelineIR;
import org.logstash.queue.ReadClient;
import org.logstash.queue.WriteClient;
import sun.plugin2.main.server.Plugin;

public class Builder {
    private final PipelineIR pipelineIR;
    private int workersCount = Runtime.getRuntime().availableProcessors();
    private String pipelineId = "main";
    private PluginFactory pluginFactory;
    private ReadClient readClient;
    private WriteClient writeClient;

    public Builder(PipelineIR ir) {
        pipelineIR = ir;
    }

    public Runner build() throws IllegalArgumentException {
        if(pluginFactory  == null) {
            throw new IllegalArgumentException("You need to specify a plugin factory");
        }

        if(readClient == null ) {
            throw new IllegalArgumentException("You need to specify a read client");
        }

        if(writeClient == null) {
            throw new IllegalArgumentException("You need to specify a write client");
        }

        return new Runner(pipelineId, pipelineIR, workersCount, readClient, writeClient);
    }

    public Builder workers(int count) {
        workersCount = count;
        return this;
    }

    public Builder pipelineId(String id) {
        pipelineId = id;
        return this;
    }

    public Builder pluginFactory(PluginFactory factory) {
        pluginFactory = factory;
        return this;
    }

    public Builder readClient(ReadClient reader) {
        readClient = reader;
        return this;
    }

    public Builder writeClient(WriteClient writer) {
        writeClient = writer;
        return this;
    }
}
