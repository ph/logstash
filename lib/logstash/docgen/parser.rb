module LogStash::Docgen
  class PluginContext
    attr_accessor :description, :config_name, :config
  
    def initialize
      @config = Hash.new({})
    end

    def add_config(name, description, attributes = {})
      @config[name] = { :description => description, :attributes => attributes }
    end
  end

  class DynamicParser
  end

  # This class only do the static parsing
  # options and comments
  class Parser
    COMMENT_RE = /^ *#(?: (.*)| *$)/
    COMMENTS_IGNORE = ["encoding: utf-8"]

    def initialize
      @rules = {
        COMMENT_RE => lambda { |m| parse_comment(m[1]) },
        /^ *class.*< *(::)?LogStash::(Outputs|Filters|Inputs|Codecs)::(Base|Threadable)/ => lambda { |m| parse_class_description },
        /^ *config +[^=].*/ => lambda { |m| parse_config(m[0]) },
        /^ *config_name .*/ => lambda { |m| parse_config_name(m[0]) },
        /^ *(class|def|module) / => lambda { |m| reset_buffer },
      }

      @context = PluginContext.new

      reset_buffer
    end

    def parse_class_description
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
      return @context
    end

    def extract_lines(string)
      buffer = ""
      string.split(/\r\n|\n/).collect do |line|
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
    def self.generate(context)
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
