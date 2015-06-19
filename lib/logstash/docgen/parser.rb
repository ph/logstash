module LogStash::Docgen
  class PluginContext
    attr_accessor :description, :config_name, :section, :class_name
  
    def initialize
      @config = Hash.new({})
    end

    def add_config(name, description, attributes = {})
      @config[name] = { :description => description, :attributes => attributes }
    end

    def config
      @config
    end
  end

  class DynamicParser
    def initialize(file, context)
      @file = file
      @context = context
    end

    def parse
      load @file
      klass
    end

    def klass
      @context.class_name.split('::').inject(Object) { |memo,name| memo = memo.const_get(name); memo }
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
      }

      @context = PluginContext.new

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
      @context.add_config(field_name, flush_buffer)
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
