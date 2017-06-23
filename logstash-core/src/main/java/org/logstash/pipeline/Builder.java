package org.logstash.pipeline;

import org.logstash.config.ir.PipelineIR;
import org.logstash.queue.ReadClient;
import org.logstash.queue.WriteClient;

public class Builder {
    private int workersCount = Runtime.getRuntime().availableProcessors();
    private String pipelineId = "main";
    private ReadClient readClient;
    private WriteClient writeClient;
    private Execution execution;
    private InputSource inputSource;

    public Builder(Execution execution, InputSource inputSource) {
        this.execution = execution;
        this.inputSource = inputSource;
    }

    public Runner build() throws IllegalArgumentException {
        if(execution == null) {
            throw new IllegalArgumentException("You need to specify a plugin factory");
        }

        if(readClient == null ) {
            throw new IllegalArgumentException("You need to specify a read client");
        }

        if(writeClient == null) {
            throw new IllegalArgumentException("You need to specify a write client");
        }

        return new Runner(pipelineId, execution, inputSource, workersCount, readClient, writeClient);
    }

    public Builder workers(int count) {
        workersCount = count;
        return this;
    }

    public Builder pipelineId(String id) {
        pipelineId = id;
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
