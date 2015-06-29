module LogStash::Docgen
  class PluginContext
    CONFIG_DEFAULT_VALUES = { :attributes => {} }

    attr_accessor :description, :config_name, :section, :class_name
  
    def initialize
      @config = {}
    end

    def add_config_description(name, description)
      puts [name, description].join(' -- ')
      @config[name] ||= CONFIG_DEFAULT_VALUES
      @config[name][:description] = description
    end

    def add_config_attributes(name, attributes = {})
      @config[name] ||= CONFIG_DEFAULT_VALUES
      @config[name][:attributes] = attributes
    end

    # Developper can declare options in the order they want
    # `Hash` keys are sorted by default in the order of creation.
    def config
      # @config.sort_by { |k, v| k }
      @config
    end
  end

  # Since we can use ruby code to generate some of the options
  # like the allowed values we need to actually ask the class to return the
  # evaluated values and another process will merge the values with the extracted
  # description. Some plugins uses constant to defined the list of valid values.
  class DynamicParser
    def initialize(file, context)
      @file = file
      @context = context
    end

    # The parse method will actually force a load on the file
    # So the last version is available in the namespace.
    def parse
      load @file

      klass.get_config.each do |name, attributes|
        @context.add_config_attributes(name, attributes)
      end

      extract_modules_source_location
    end
    
    # Find all the modules included by the specified class
    # and use `source_location` to find the actual file on disk.
    # We need to cleanup the values for evalued modules or system module.
    # `included_modules` will return the list of module in the order they appear.
    # this is important because modules can override the documentation of some option.
    def extract_modules_source_location
      klass.included_modules
        .collect { |m| m.instance_methods.collect { |method| m.instance_method(method).source_location } }
        .compact
        .collect(&:first)
        .flatten
        .uniq
        .reject { |source| !source.is_a?(String) || source == "(eval)" }
    end

    def klass
      @klass ||= @context.class_name.split('::').inject(Object) do |memo,name|
        memo = memo.const_get(name); memo
      end
    end
  end

  # This class only do the static parsing
  # options and comments
  class StaticParser
    COMMENT_RE = /^ *#(?: (.*)| *$)/
    ENDLINES_RE = /\r\n|\n/
    COMMENTS_IGNORE = ["encoding: utf-8"]

    def initialize(context)
      @rules = {
        COMMENT_RE => lambda { |m| parse_comment(m[1]) },
        /^ *class\s(.*) < *(::)?LogStash::(Outputs|Filters|Inputs|Codecs)::(Base|Threadable)/ => lambda { |m| parse_class_description(m) },
        /^ *config +[^=].*/ => lambda { |m| parse_config(m[0]) },
        /^ *config_name .*/ => lambda { |m| parse_config_name(m[0]) },
        /^ *(class|def|module) / => lambda { |m| reset_buffer },
      }

      @context = context

      reset_buffer
    end

    def parse_class_description(class_definition)
      @context.section = class_definition[3].downcase.gsub(/s$/, '')
      @context.class_name = class_definition[1]
      @context.description = flush_buffer
    end

    def parse_config_name(name)
      @context.config_name = name.match(/config_name\s+\"(\w+)\"/)[1]
    end
    
    def parse_comment(comment)
      return if ignore_comment?(comment)
      @buffer << comment
    end

    def parse_config(field)
      field_name = field.match(/config\s+:(\w+),/)[1]
      @context.add_config_description(field_name, flush_buffer)
    end

    def parse(file)
      reset_buffer
      string = File.read(file)
      extract_lines(string).each { |line| parse_line(line) }
    end

    def extract_lines(string)
      buffer = ""
      string.split(ENDLINES_RE).collect do |line|
        # Join long lines
        if line =~ COMMENT_RE
          # nothing
        else
          # Join extended lines
          if line =~ /(, *$)|(\\$)|(\[ *$)/
            buffer += line.gsub(/\\$/, "")
            next
          end
        end

        line = buffer + line
        buffer = ""

        line
      end
    end

    def parse_line(line)
      @rules.each do |re, action|
        if m = re.match(line)
          action.call(m)
        end
      end 
    end

    def ignore_comment?(comment)
      COMMENTS_IGNORE.include?(comment)
    end

    def flush_buffer
      content = @buffer.join("\n")
      reset_buffer
      content
    end

    def reset_buffer
      @buffer = []
    end
  end

  class Parser
    def self.parse(file)
      context =  PluginContext.new

      # This is a 3 phases parsing.
      # - static
      # - dynamic to get the includes modules and the rubycode
      # - static for module includes to aggregate the description
      static = StaticParser.new(context)
      static.parse(file)

      dynamic = DynamicParser.new(file, context)
      dynamic.parse
      dynamic.extract_modules_source_location.each { |f| static.parse(f) }
      context
    end
  end
  
  class Asciidoc
    def generate(context)
    end
  end

  #
  # doc representation
  class HelpFormat
    def generate(context)
      puts context.section + " " + context.class_name
      puts "\n\n"
      puts context.config_name
      puts "\n\n"
      puts context.description
      puts "\n\n"
      
      context.config.each do |name, options|
        puts name
        puts options.inspect
        puts "\n\n"
      end
    end
  end
end
