package org.logstash.pipeline;

import java.util.Map;

public interface PluginFactory {
    public BaseProcessor create(String pluginType, String pluginName, Map<String, String> settings);
}
