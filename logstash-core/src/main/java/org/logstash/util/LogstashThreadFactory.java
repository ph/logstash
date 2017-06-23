package org.logstash.util;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;

public class LogstashThreadFactory implements ThreadFactory {
    private String prefix;
    private final AtomicInteger threadCount = new AtomicInteger(1);


    public LogstashThreadFactory(String prefix) {
        this.prefix = prefix;
    }

    @Override
    public Thread newThread(Runnable r) {
        String worker = ((LogstashWorker) r).getWorkerName();
        String name = prefix + worker + "-" + threadCount.getAndIncrement();
        return new Thread(r, name);
    }
}
