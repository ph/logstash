package com.logstash;

/**
 * Created by ph on 15-05-22.
 */
public interface TemplateNode {
    String evaluate(Event event);
}
