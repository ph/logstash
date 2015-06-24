module LogStash::Docgen
  class PluginContext
    attr_accessor :description, :config_name, :section, :class_name
    attr_reader :config
  
    def initialize
      @config = Hash.new({ :description => "", :attributes => {} })
    end

    def add_config(name, attributes = {}, description = nil)
      @config[name][:description] = description if description
      @config[name][:attributes] = @config[:name][:attributes].merge(attributes)
    end
  end

  # Since we can use ruby in the code to generate some of the options
  # like the allowed values we need to actually ask the class to return the
  # evaluated values
  class DynamicParser
    def initialize(file, context)
      @file = file
      @context = context
    end

    def parse
      load @file
      klass.get_config.each do |name, attributes|
        @context.add_config(name, attributes)
      end
    end

    def klass
      @context.class_name.split('::').inject(Object) do |memo,name|
        memo = memo.const_get(name); memo
      end
    end
  end

  # This class only do the static parsing
  # options and comments
  class Parser
    COMMENT_RE = /^ *#(?: (.*)| *$)/
    ENDLINES_RE = /\r\n|\n/
    COMMENTS_IGNORE = ["encoding: utf-8"]

    def initialize
      @rules = {
        COMMENT_RE => lambda { |m| parse_comment(m[1]) },
        /^ *class\s(.*) < *(::)?LogStash::(Outputs|Filters|Inputs|Codecs)::(Base|Threadable)/ => lambda { |m| parse_class_description(m) },
        /^ *config +[^=].*/ => lambda { |m| parse_config(m[0]) },
        /^ *config_name .*/ => lambda { |m| parse_config_name(m[0]) },
        /^ *(class|def|module) / => lambda { |m| reset_buffer },
        /^ *include\s(.+)/ => lambda { |match| parse_include(match[1]) }
      }

      @context = PluginContext.new
      @deferred_includes = []

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
      @context.add_config(field_name, {}, flush_buffer)
    end

    def parse_include(target)
      @deferred_includes << target
    end

    def parse(file)
      string = File.read(file)
      extract_lines(string).each { |line| parse_line(line) }

      dynamic = DynamicParser.new(file, @context)
      dynamic.parse

      return @context
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

    def self.parse(file)
      new.parse(file)
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
        puts options[:description]
        puts "\n\n"
      end
    end
  end
end
