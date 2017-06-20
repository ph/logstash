package org.logstash.pipeline;

import org.logstash.queue.WriteClient;

/**
 * Created by ph on 2017-06-14.
 */
public interface InputProcessor {
    public void process(WriteClient writeClient);
}
