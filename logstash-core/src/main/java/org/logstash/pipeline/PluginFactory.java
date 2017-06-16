package org.logstash.pipeline;

import org.logstash.config.ir.PluginDefinition;

public interface PluginFactory {
    public BaseProcessor create(PluginDefinition pluginDefinition);
}
