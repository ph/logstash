package com.logstash;

/**
 * Created by ph on 15-05-22.
 */
public class KeyNode implements TemplateNode {
    private String key;

    public KeyNode(String key) {
        this.key = key;
    }

    /**
     This will be more complicated with hash and array.
     leverage jackson lib to do the actual.
     */
    public String evaluate(Event event) {
        return String.valueOf(event.getField(this.key));
    }
}