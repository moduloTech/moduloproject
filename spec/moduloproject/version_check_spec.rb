# frozen_string_literal: true

require 'fileutils'
require 'json'

RSpec.describe Moduloproject::VersionCheck do
  let(:cache_dir) { File.expand_path('~/.moduloproject') }
  let(:cache_file) { File.join(cache_dir, 'version_cache.json') }
  let(:rubygems_url) { 'https://rubygems.org/api/v1/gems/moduloproject.json' }

  around do |example|
    # Backup existing cache if present
    original_cache = File.read(cache_file) if File.exist?(cache_file)
    FileUtils.rm_f(cache_file)

    # Backup environment variables
    original_ci = ENV.fetch('CI', nil)
    original_gitlab_ci = ENV.fetch('GITLAB_CI', nil)
    ENV.delete('CI')
    ENV.delete('GITLAB_CI')

    example.run

    # Clean up cache created during test
    FileUtils.rm_f(cache_file)

    # Restore original cache
    File.write(cache_file, original_cache) if original_cache

    # Restore environment variables
    ENV['CI'] = original_ci if original_ci
    ENV['GITLAB_CI'] = original_gitlab_ci if original_gitlab_ci
  end

  describe '.check_and_notify' do
    context 'when in CI environment' do
      it 'skips check when CI=true' do
        ENV['CI'] = 'true'
        allow(Net::HTTP).to receive(:get_response)

        described_class.check_and_notify

        expect(Net::HTTP).not_to have_received(:get_response)
      end

      it 'skips check when GITLAB_CI is set' do
        ENV['GITLAB_CI'] = 'true'
        allow(Net::HTTP).to receive(:get_response)

        described_class.check_and_notify

        expect(Net::HTTP).not_to have_received(:get_response)
      end
    end

    context 'when cache is valid' do
      before do
        FileUtils.mkdir_p(cache_dir)
        cache_data = { version: '3.0.0', timestamp: Time.now.to_i }
        File.write(cache_file, JSON.generate(cache_data))
      end

      it 'uses cached version without API call' do
        allow(Net::HTTP).to receive(:get_response)

        described_class.check_and_notify

        expect(Net::HTTP).not_to have_received(:get_response)
      end
    end

    context 'when cache is expired' do
      before do
        FileUtils.mkdir_p(cache_dir)
        old_timestamp = Time.now.to_i - (25 * 60 * 60) # 25 hours ago
        cache_data = { version: '3.0.0', timestamp: old_timestamp }
        File.write(cache_file, JSON.generate(cache_data))
      end

      it 'fetches from RubyGems API' do
        request = stub_request(:get, rubygems_url)
                  .to_return(status: 200, body: '{"version":"3.0.0"}')

        described_class.check_and_notify

        expect(request).to have_been_requested
      end
    end

    context 'when a newer version is available' do
      before do
        stub_request(:get, rubygems_url)
          .to_return(status: 200, body: '{"version":"3.1.0"}')
      end

      it 'calls display_update_notification with the latest version' do
        allow(described_class).to receive(:display_update_notification)

        described_class.check_and_notify

        expect(described_class).to have_received(:display_update_notification).with('3.1.0')
      end
    end

    context 'when current version is up to date' do
      before do
        stub_request(:get, rubygems_url)
          .to_return(status: 200, body: '{"version":"3.0.0"}')
      end

      it 'does not call display_update_notification' do
        allow(described_class).to receive(:display_update_notification)

        described_class.check_and_notify

        expect(described_class).not_to have_received(:display_update_notification)
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get, rubygems_url).to_timeout
      end

      it 'fails silently without raising' do
        expect { described_class.check_and_notify }.not_to raise_error
      end
    end

    context 'when cache file is corrupted' do
      before do
        FileUtils.mkdir_p(cache_dir)
        File.write(cache_file, 'invalid json')
        stub_request(:get, rubygems_url)
          .to_return(status: 200, body: '{"version":"3.0.0"}')
      end

      it 'fetches from API and recovers' do
        expect { described_class.check_and_notify }.not_to raise_error
      end
    end
  end

  describe '.display_update_notification' do
    it 'outputs notification to stderr' do
      expect { described_class.send(:display_update_notification, '3.1.0') }
        .to output(/new version.*available/i).to_stderr
    end

    it 'shows current and latest versions' do
      expect { described_class.send(:display_update_notification, '3.1.0') }
        .to output(/3\.0\.0.*3\.1\.0/m).to_stderr
    end
  end
end
