package com.logstash;

import com.sun.javafx.tools.ant.DeployFXTask;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

public class StringInterpolation {
    static Map cache;
    static Pattern OPEN_TAG = Pattern.compile("%{}");
    static Pattern CLOSE_TAG = Pattern.compile("}");

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


        for (int i = 0; i < nodes.size(); i++) {
            results.append(((TemplateNode) nodes.get(i)).evaluate(event));
        }

        return results.toString();
    }

    public List compile(String template) {
        List nodes = new ArrayList<TemplateNode>();

        Scanner scanner = new Scanner(template);
        String content;

        bf = BufferedReader.new(template);



        return nodes;
    }

    public TemplateNode identifyTag(String tag) {
        return new KeyNode("awesome");
    }

    public static StringInterpolation getInstance() {
        return HoldCurrent.INSTANCE;
    }
}