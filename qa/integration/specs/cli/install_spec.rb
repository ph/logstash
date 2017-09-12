# encoding: utf-8
require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
require_relative "../../framework/helpers"
require "logstash/devutils/rspec/spec_helper"
require "stud/temporary"
require "fileutils"
require "ostruct"

def gem_in_lock_file?(pattern, lock_file)
  content =  File.read(lock_file)
  content.match(pattern)
end

def backup_files(*files)
  files.flatten.collect { |file| backup_file(file) }
end

def backup_file(file_to_backup)
  file_to_backup = File.expand_path(file_to_backup)
  tmp_directory = Stud::Temporary.pathname
  FileUtils.mkdir_p(tmp_directory)
  backup_to_file = File.join(tmp_directory, File::SEPARATOR, File.basename(file_to_backup))

  FileUtils.cp(file_to_backup, backup_to_file)
  OpenStruct.new(:original_path => file_to_backup, :backup_file => backup_to_file)
end

def restore_files(*backuped_files)
  backuped_files.flatten.each { |backup_file| FileUtils.cp(backup_file.backup_file, backup_file.original_path) }
end

def set_gemspec_version(version, template, target)
  content = File.read(template)
  content.gsub!("{VERSION}", version)
  IO.write(target, content)
end

describe "CLI > logstash-plugin install" do

  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @logstash_plugin = @logstash.plugin_cli
  end

  let(:fixtures_directory) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures")) }

  shared_examples "install from a pack" do
    let(:pack) { "file://#{File.join(fixtures_directory, "logstash-dummy-pack", "logstash-dummy-pack.zip")}" }
    let(:install_command) { "bin/logstash-plugin install" }
    let(:change_dir) { true }
    let(:installed_plugin) { "logstash-output-secret" }
    let(:installed_dependency) { "gemoji" }

    # When you are on anything by linux we won't disable the internet with seccomp
    if RbConfig::CONFIG["host_os"] == "linux"
      context "without internet connection (linux seccomp wrapper)" do

        let(:offline_wrapper_path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "offline_wrapper")) }

        before do
          Dir.chdir(offline_wrapper_path) do
            system("make clean")
            system("make")
          end
        end

        let(:offline_wrapper_cmd) { File.join(offline_wrapper_path, "offline") }

        it "successfully install the pack" do
          execute = @logstash_plugin.run_raw("#{offline_wrapper_cmd} #{install_command} #{pack}", change_dir)

          expect(execute.stderr_and_stdout).to match(/Install successful/)
          expect(execute.exit_code).to eq(0)

          installed = @logstash_plugin.list(installed_plugin)
          expect(installed.stderr_and_stdout).to match(/#{installed_plugin}/)

          expect(gem_in_lock_file?(/#{installed_dependency}/, @logstash.lock_file)).to be_truthy
        end
      end
    else

      context "with internet connection" do
        it "successfully install the pack" do
          execute = @logstash_plugin.run_raw("#{install_command} #{pack}", change_dir)

          expect(execute.stderr_and_stdout).to match(/Install successful/)
          expect(execute.exit_code).to eq(0)

          installed = @logstash_plugin.list(installed_plugin)
          expect(installed.stderr_and_stdout).to match(/#{installed_plugin}/)

          expect(gem_in_lock_file?(/#{installed_dependency}/, @logstash.lock_file)).to be_truthy
        end
      end
    end
  end

  context "pack" do
    context "when the command is run in the `$LOGSTASH_HOME`" do
      include_examples "install from a pack"
    end

    context "when the command is run outside of the `$LOGSTASH_HOME`" do
      include_examples "install from a pack" do
        let(:change_dir) { false }
        let(:install_command) { "#{@logstash.logstash_home}/bin/logstash-plugin install" }

        before :all do
          @current = Dir.pwd
          tmp = Stud::Temporary.pathname
          FileUtils.mkdir_p(tmp)
          Dir.chdir(tmp)
        end

        after :all do
          Dir.chdir(@current)
        end
      end
    end

    context "when the pack contains an updated gem" do
      let(:upgradeable_pack_directory) { File.expand_path(File.join(fixtures_directory, "logstash-upgradeable-pack")) }
      let(:stud_virtual_gemspec) { File.join(upgradeable_pack_directory, "stud.gemspec") }
      let(:stud_virtual_gemspec_template) { "#{stud_virtual_gemspec}.template" }
      # Use a shell scripts to generate a custom pack, using the virtual gemspec
      let(:create_pack_cmd) { "./bundle.sh" }
      let(:stud_version) { "0.0.24" }

      before :each do
        @backup = backup_files(
          File.join(@logstash.logstash_home, "Gemfile"),
          File.join(@logstash.logstash_home, "Gemfile.jruby-2.3.lock")
        )

        set_gemspec_version(stud_version, stud_virtual_gemspec_template, stud_virtual_gemspec)

        Dir.chdir(upgradeable_pack_directory) do
          system(create_pack_cmd)
        end
      end

      after :each do
        restore_files(@backup)
        FileUtils.rm(stud_virtual_gemspec)
      end

      include_examples "install from a pack" do
        let(:pack) { "file://#{File.join(upgradeable_pack_directory, "logstash-upgradeable-pack.zip")}" }
        let(:installed_plugin) { "logstash-input-secret" }
        let(:installed_dependency) { "stud" }
      end
    end
  end
end
