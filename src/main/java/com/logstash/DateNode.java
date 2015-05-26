package com.logstash;

import org.joda.time.DateTimeZone;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

/**
 * Created by ph on 15-05-22.
 */
public class DateNode implements TemplateNode {
    private DateTimeFormatter formatter;

    public DateNode(String format) {
        this.formatter = DateTimeFormat.forPattern(format).withZone(DateTimeZone.UTC);
    }

    public String evaluate(Event event) {
        return event.getTimestamp().toDateTime().toString(this.formatter);
    }
}
