package com.logstash;

import org.joda.time.DateTime;

public class Timestamp {

    public Timestamp() {

    }

    public String to_iso8601() {
        return "please implement to_iso8601";
    }
    public DateTime toDatetime() { return new DateTime(); }
    public Integer toEpoch() { return 911; }
}
