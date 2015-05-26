package com.logstash;

/**
 * Created by ph on 15-05-22.
 */
public class EpochNode implements TemplateNode {
    public EpochNode(){ }

    public String evaluate(Event event) {
        return String.valueOf(event.getTimestamp().toEpoch());
    }
}