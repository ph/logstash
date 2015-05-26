package com.logstash;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class StringInterpolation {
    static Map cache;

    private static class HoldCurrent {
        private static final StringInterpolation INSTANCE = new StringInterpolation();
    }

    private StringInterpolation() {
        this.cache = new ConcurrentHashMap<>();
    }

    public String evaluate(Event event, String template) {
        List nodes = (List<TemplateNode>) cache.get(template);

        if(nodes == null) {
            nodes = this.compile(template);
            List set = (List<TemplateNode>) cache.putIfAbsent(template, nodes);
            nodes = (set != null) ? set : nodes;
        }

        StringBuffer results = new StringBuffer();

        for(TemplateNode node: nodes)
            results.append(node.evaluate(event));

        return results.toString();
    }

    public List compile(String template) {
        List nodes = new ArrayList<TemplateNode>();


        // implement actual string parsing here
        nodes.add(new StaticNode("/bonjour-lafamille"));
        nodes.add(new KeyNode("type"));
        nodes.add(new StaticNode("/"));
        nodes.add(new DateNode("YYYY-dd-mm"));
        nodes.add(new StaticNode("/moreinfo"));

        return nodes;
    }

    public static StringInterpolation getInstance() {
        return HoldCurrent.INSTANCE;
    }
}