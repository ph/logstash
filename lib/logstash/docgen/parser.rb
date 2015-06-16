module Docgen
  # This class only do the static parsing
  class Parser
    COMMENT_RE = /^ *#(?: (.*)| *$)/

      def initialize
        @rules = {
          COMMENT_RE => lambda { |m| add_comment(m[1]) },
          /^ *class.*< *(::)?LogStash::(Outputs|Filters|Inputs|Codecs)::(Base|Threadable)/ => lambda { |m| set_class_description },
          /^ *config +[^=].*/ => lambda { |m| add_config(m[0]) },
          /^ *config_name .*/ => lambda { |m| set_config_name(m[0]) },
          /^ *flag[( ].*/ => lambda { |m| add_flag(m[0]) },
          /^ *(class|def|module) / => lambda { |m| clear_comments },
        }
    end

    def self.parse(file)
    end
  end

  class HelpFormat
    def generate()
    end
  end
end
