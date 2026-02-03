# frozen_string_literal: true

RSpec.describe Moduloproject::CLI do
  before do
    allow(Moduloproject::VersionCheck).to receive(:check_and_notify)
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
    it 'displays not implemented message' do
      expect { described_class.start(%w[new test-app]) }.to output(/Not implemented yet/).to_stdout
    end

    it 'displays the app name' do
      expect { described_class.start(%w[new my-app]) }.to output(/Creating new project: my-app/).to_stdout
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
