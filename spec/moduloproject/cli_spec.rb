# frozen_string_literal: true

RSpec.describe Moduloproject::CLI do
  before do
    allow(Moduloproject::VersionCheck).to receive(:check_and_notify)
  end

  describe '.start' do
    context 'when MODULOPROJECT_SKIP_VERSION_CHECK is not set' do
      around do |example|
        original = ENV.fetch('MODULOPROJECT_SKIP_VERSION_CHECK', nil)
        ENV.delete('MODULOPROJECT_SKIP_VERSION_CHECK')
        example.run
        ENV['MODULOPROJECT_SKIP_VERSION_CHECK'] = original if original
      end

      it 'calls VersionCheck.check_and_notify' do
        described_class.start(['version'])
        expect(Moduloproject::VersionCheck).to have_received(:check_and_notify)
      end
    end

    context 'when MODULOPROJECT_SKIP_VERSION_CHECK is 1' do
      around do |example|
        original = ENV.fetch('MODULOPROJECT_SKIP_VERSION_CHECK', nil)
        ENV['MODULOPROJECT_SKIP_VERSION_CHECK'] = '1'
        example.run
        ENV['MODULOPROJECT_SKIP_VERSION_CHECK'] = original if original
      end

      it 'skips VersionCheck.check_and_notify' do
        described_class.start(['version'])
        expect(Moduloproject::VersionCheck).not_to have_received(:check_and_notify)
      end
    end
  end

  describe '.exit_on_failure?' do
    it 'returns true' do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe 'version command' do
    it 'displays the version' do
      expect { described_class.start(['version']) }.to output(/moduloproject 3\.0\.0/).to_stdout
    end

    it 'responds to -v flag' do
      expect { described_class.start(['-v']) }.to output(/moduloproject 3\.0\.0/).to_stdout
    end

    it 'responds to --version flag' do
      expect { described_class.start(['--version']) }.to output(/moduloproject 3\.0\.0/).to_stdout
    end
  end

  describe 'new command' do
    before do
      allow(Moduloproject::Commands::New).to receive(:new).and_return(
        instance_double(Moduloproject::Commands::New, execute: nil)
      )
    end

    it 'shows supported Rails versions in help' do
      expect { described_class.start(%w[help new]) }.to output(/default: 8\.1, supported: 7\.2, 8\.0, 8\.1/).to_stdout
    end

    it 'creates a Commands::New instance with correct arguments' do
      expect(Moduloproject::Commands::New).to receive(:new).with(
        'test-app',
        hash_including('frontend' => 'vue')
      )
      described_class.start(%w[new test-app])
    end

    it 'passes custom options' do
      expect(Moduloproject::Commands::New).to receive(:new).with(
        'my-app',
        hash_including('frontend' => 'hotwire')
      )
      described_class.start(%w[new my-app --frontend hotwire])
    end

    context 'when ArgumentError is raised' do
      before do
        allow(Moduloproject::Commands::New).to receive(:new).and_raise(ArgumentError, 'Invalid name')
      end

      it 'displays error and exits' do
        expect do
          described_class.start(%w[new test-app])
        end.to raise_error(SystemExit)
      end
    end
  end

  describe 'sync command' do
    it 'displays not implemented message' do
      expect { described_class.start(['sync']) }.to output(/Not implemented yet/).to_stdout
    end
  end

  describe 'diff command' do
    it 'displays not implemented message' do
      expect { described_class.start(['diff']) }.to output(/Not implemented yet/).to_stdout
    end
  end

  describe 'init command' do
    it 'displays not implemented message' do
      expect { described_class.start(['init']) }.to output(/Not implemented yet/).to_stdout
    end
  end

  describe 'templates command' do
    it 'displays not implemented message' do
      expect { described_class.start(['templates']) }.to output(/Not implemented yet/).to_stdout
    end
  end
end
