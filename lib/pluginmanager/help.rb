require "lib/logstash/docgen/parser"
require "stud/temporary"
require "launchy"

class LogStash::PluginManager::Help < LogStash::PluginManager::Command
  parameter "[PLUGIN]", "Display help for this plugin"
  option "--asciidoc", :flag, "output an asciidoc"

  def execute
    LogStash::Bundler.setup!({:without => [:build, :development]})

    signal_usage_error("You have to specify a plugin") unless plugin
    signal_usage_error("This plugin doesn't exist") unless plugin_paths

    context = LogStash::Docgen::Parser.parse(plugin_paths.first)

    if asciidoc?
      tmpfile = Stud::Temporary.file
      help = LogStash::Docgen::AsciidocFormat.new(:raw => false)
      tmpfile.write(help.generate(context))
      Launchy.open(tmpfile.path)
    else
      context = LogStash::Docgen::Parser.parse(plugin_paths.first)
      help = LogStash::Docgen::HelpFormat.new()
      puts help.generate(context)
    end
  end

  def plugin_paths
    @plugin_paths =  begin
                      gemspecs = LogStash::PluginManager.find_plugins_gem_specs(plugin)
                      return [] if gemspecs.empty?
                      Dir.glob(File.join(gemspecs.first.gem_dir, "lib", "logstash", "{input,output,filter,codec}s", "*.rb"))
                    end
  end
end
