task "Generate documentation for the current plugin"
task :doc, [:browser] do
  args.with_defaults(:browser => true)

  require "bootstrap/environment"
  require "lib/logstash/docgen"
  require "stud/temporary"
  require "launchy"

  pattern = "#{LogStash::Environment.logstash_gem_home}/gems/logstash-*/lib/logstash/{input,output,filter,codec}s/*.rb"

  # Should give us an actual plugin root in most cases.
  files = Dir.glob(pattern)
  context = LogStash::Docgen::Parser.parse(files.first)
  format = LogStash::Docgen::AsciidocFormat.new(:raw => false)
    
  if args[:browser]
    tmpfile = Stud::Temporary.file
    tmpfile.write(format.generate(context))
    Launchy.open(tmpfile.path)
  else
    puts format.generate(context)
  end
end
