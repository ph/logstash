package org.logstash.pipeline;

import org.logstash.config.ir.PipelineIR;

public class Builder {
    private final PipelineIR pipelineIR;
    private int workersCount = Runtime.getRuntime().availableProcessors();
    private int batchSize = 125;
    private String pipelineId = "main";

    public Builder(PipelineIR ir) {
        pipelineIR = ir;
    }

    public Runner build() {
        return new Runner();
    }

    public Builder workers(int count) {
        workersCount = count;
        return this;
    }

    public Builder pipelineId(String id) {
        pipelineId = id;
        return this;
    }

    public Builder batch(int size) {
        batchSize = size;
        return this;
    }
}
