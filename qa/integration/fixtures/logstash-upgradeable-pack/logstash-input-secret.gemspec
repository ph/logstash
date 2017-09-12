Gem::Specification.new do |s|
  s.name          = 'logstash-input-secret'
  s.version       = '0.1.0'
  s.licenses      = ['Apache License (2.0)']
  s.summary       = 'Test the upgrade gems from a pack'
  s.description   = 'Test the upgrade gems from a pack'
  s.homepage      = 'https://github.com/ph/secret'
  s.authors       = ['Pier-Hugues Pellerin']
  s.email         = 'phpellerin@gmail.com'
  s.require_paths = ['lib']

  # Make sure we cannot publish this dummy gem on rubygems
  # its only used in the integration suite.
  s.metadata['allowed_push_host'] = 'http://localhost'

  # Files
  s.files = Dir['logstash-input-secret.gemspec']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  s.add_runtime_dependency "stud", "~> 0"
end
