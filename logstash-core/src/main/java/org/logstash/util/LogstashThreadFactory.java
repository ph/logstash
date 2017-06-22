package org.logstash.util;
import java.util.concurrent.ThreadFactory;

public class LogstashThreadFactory implements ThreadFactory {
    private final String prefix;

    public LogstashThreadFactory(String prefix) {
        this.prefix = prefix;
    }

    public LogstashThreadFactory() {
        this.prefix = "thread-";
    }

    @Override
    public Thread newThread(Runnable r) {
        String name = this.prefix + ((LogstashWorker) r).getWorkerName();
        return new Thread(r, name);
    }
}
