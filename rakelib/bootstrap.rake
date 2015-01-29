# Trying to simplify the build process, we have dependencies all
# over the place.
task "bootstrap:jruby" => ["vendor:jruby", "vendor:minimal-gems"]
task "bootstrap" => [ "vendor:gems", "vendor:kibana", "compile:all" ]
task "bootstrap:test" => [ "vendor:test", "compile:all" ]
