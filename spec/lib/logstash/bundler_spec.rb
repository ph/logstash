# encoding: utf-8
require "spec_helper"
require "logstash/bundler"

describe LogStash::Bundler do
  shared_examples 'clean gems' do
    it 'should include --clean' do
      options.merge!({ :clean => true })
      expect(subject.bundler_arguments(options)).to include("--clean")
    end

    it 'shouldnt include --clean if not specified' do
      options.merge!({ :clean => false })
      expect(subject.bundler_arguments(options)).not_to include("--clean")
    end
  end

  context "capture_stdout" do
    it "should capture stdout from block" do
      original_stdout = $stdout
      output, exception = LogStash::Bundler.capture_stdout do
        expect($stdout).not_to eq(original_stdout)
        puts("foobar")
      end
      expect($stdout).to eq(original_stdout)
      expect(output).to eq("foobar\n")
      expect(exception).to eq(nil)
    end

    it "should capture stdout and report exception from block" do
      output, exception = LogStash::Bundler.capture_stdout do
        puts("foobar")
        raise(StandardError, "baz")
      end
      expect(output).to eq("foobar\n")
      expect(exception).to be_a(StandardError)
      expect(exception.message).to eq("baz")
    end
  end

  context 'when generating bundler arguments' do
    context 'when installing' do
      let(:options) { { :install => true, :without => [:development]} }

      include_examples 'clean gems'

      it 'specify the gemfile' do
        expect(subject.bundler_arguments(options)).to include("--gemfile=#{LogStash::Environment::GEMFILE_PATH}")
      end

      it 'specify path to install the gems' do
        expect(subject.bundler_arguments(options)).to include('--path', LogStash::Environment::BUNDLE_DIR)
      end
    end

    context "when updating" do
      let(:options) { { :without => [:development] } }

      include_examples 'clean gems'

      it 'should update a specific plugin' do
        options.merge!(:update => ['logstash-input-awesome'])
        expect(subject.bundler_arguments(options)).to include('update', 'logstash-input-awesome')
      end

      it 'should update multiple plugins' do
        options.merge!(:update => ['logstash-input-awesome', 'logstash-filter-grok'])
        expect(subject.bundler_arguments(options)).to include('update', 'logstash-input-awesome', 'logstash-filter-grok')
      end
    end
  end
end

