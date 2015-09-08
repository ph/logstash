# encoding: utf-8
require "bootstrap/environment"

module LogStash
  module Rubygems
    extend self

    def patch!
      # monkey patch RubyGems to silence ffi warnings:
      #
      # WARN: Unresolved specs during Gem::Specification.reset:
      #       ffi (>= 0)
      # WARN: Clearing out unresolved specs.
      # Please report a bug if this causes problems.
      #
      # see https://github.com/elasticsearch/logstash/issues/2556 and https://github.com/rubygems/rubygems/issues/1070
      #
      # this code is from Rubygems v2.1.9 in JRuby 1.7.17. Per tickets this issue should be solved at JRuby >= 1.7.20.
      #
      # this method implementation works for Rubygems version 2.1.0 and up, verified up to 2.4.6
      if ::Gem::Version.new(::Gem::VERSION) >= ::Gem::Version.new("2.1.0") && ::Gem::Version.new(::Gem::VERSION) < ::Gem::Version.new("2.5.0")
        ::Gem::Specification.class_exec do
          def self.reset
            @@dirs = nil
            ::Gem.pre_reset_hooks.each { |hook| hook.call }
            @@all = nil
            @@stubs = nil
            _clear_load_cache
            unresolved = unresolved_deps
            unless unresolved.empty?
              unless (unresolved.size == 1 && unresolved["ffi"])
                w = "W" + "ARN"
                warn "#{w}: Unresolved specs during Gem::Specification.reset:"
                unresolved.values.each do |dep|
                  warn "      #{dep}"
                end
                warn "#{w}: Clearing out unresolved specs."
                warn "Please report a bug if this causes problems."
              end
              unresolved.clear
            end
            ::Gem.post_reset_hooks.each { |hook| hook.call }
          end
        end
      end

      if LogStash::Environment.windows?
        # Make sure `FileUtils.chmod` is a no op operation on windows when uncompressing the
        # gems, we have seen unreliable install of gem like the `docker-api` see theses issues:
        # https://github.com/elastic/logstash/issues/3829
        # https://github.com/jruby/jruby/issues/2498
        ::Gem::Package.class_exec do
          def extract_tar_gz io, destination_dir, pattern = "*" # :nodoc:
            open_tar_gz io do |tar|
              tar.each do |entry|
                next unless File.fnmatch pattern, entry.full_name, File::FNM_DOTMATCH

                destination = install_location entry.full_name, destination_dir

                FileUtils.rm_rf destination

                mkdir_options = {}
                mkdir_options[:mode] = entry.header.mode if entry.directory?
                mkdir =
                  if entry.directory? then
                    destination
                  else
                    File.dirname destination
                  end

                FileUtils.mkdir_p mkdir, mkdir_options

                open destination, 'wb' do |out|
                  out.write entry.read
                end if entry.file?

                verbose destination
              end
            end
          end
        end
      end
    end


    # Take a gem package and extract it to a specific target
    # @param [String] Gem file, this must be a path
    # @param [String, String] Return a Gem::Package and the installed path
    def unpack(file, path)
      require "rubygems/package"
      require "securerandom"

      # We are creating a random directory per extract,
      # if we dont do this bundler will not trigger download of the dependencies.
      # Use case is:
      # - User build his own gem with a fix
      # - User doesnt increment the version
      # - User install the same version but different code or dependencies multiple times..
      basename  = ::File.basename(file, '.gem')
      unique = SecureRandom.hex(4)
      target_path = ::File.expand_path(::File.join(path, unique, basename))

      package = ::Gem::Package.new(file)
      package.extract_files(target_path)

      return [package, target_path]
    end

  end
end
