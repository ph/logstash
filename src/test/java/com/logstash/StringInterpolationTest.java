package com.logstash;


import org.junit.Test;
import static org.junit.Assert.*;


public class StringInterpolationTest {
    @Test
    public void testCompletelyStaticTemplate() {
        Event event = new Event();

        String path = "/full/path/awesome";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals(si.evaluate(event, path), path);
    }
}
