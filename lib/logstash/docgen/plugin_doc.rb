require "bootstrap/environment"
require "logstash/docgen/parser"
require "stud/temporary"
require "launchy"

namespace :doc do
  desc "Preview HTML documentation in your browser"
  task :html do
    tmpfile = Stud::Temporary.file
    tmpfile.write(generate_preview(:raw => false))
    Launchy.open(tmpfile.path)
  end

  desc "Preview Asciidoc documentation"
  task :asciidoc do
    puts generate_preview
  end

  namespace :html do
    desc "Preview the raw HTML of the documentation"
    task :raw do
      puts generate_preview(:raw => false)
    end
  end
end

task :doc => "doc:html"

def generate_preview(options = { :raw => true })
  pattern = "#{Dir.pwd}/lib/logstash/{input,output,filter,codec}s/*.rb"

  # Should give us an actual plugin root in most cases.
  files = Dir.glob(pattern)
  context = LogStash::Docgen::Parser.parse(files.first)
  format = LogStash::Docgen::AsciidocFormat.new(options)

  format.generate(context)
end
