# frozen_string_literal: true

require 'json'
require 'net/http'
require 'fileutils'

module Moduloproject
  class VersionCheck
    CACHE_DIR = File.expand_path('~/.moduloproject')
    CACHE_FILE = File.join(CACHE_DIR, 'version_cache.json')
    CACHE_TTL = 24 * 60 * 60 # 24 hours in seconds
    RUBYGEMS_API_URL = 'https://rubygems.org/api/v1/gems/moduloproject.json'

    class << self
      def check_and_notify
        return if skip_check?

        latest = fetch_latest_version
        return unless latest && newer_version?(latest)

        display_update_notification(latest)
      rescue StandardError
        # Silently fail - version check should never break the CLI
        nil
      end

      private

      def skip_check?
        ci_environment?
      end

      def ci_environment?
        ENV['CI'] == 'true' || ENV['CONTINUOUS_INTEGRATION'] == 'true' || ENV['GITLAB_CI'].to_s != ''
      end

      def fetch_latest_version
        cached = read_cache
        return cached['version'] if cached && cache_valid?(cached)

        version = fetch_from_rubygems
        write_cache(version) if version
        version
      end

      def cache_valid?(cached)
        return false unless cached['timestamp']

        Time.now.to_i - cached['timestamp'] < CACHE_TTL
      end

      def read_cache
        return nil unless File.exist?(CACHE_FILE)

        JSON.parse(File.read(CACHE_FILE))
      rescue JSON::ParserError
        nil
      end

      def write_cache(version)
        FileUtils.mkdir_p(CACHE_DIR)
        File.write(CACHE_FILE, JSON.generate(version: version, timestamp: Time.now.to_i))
      end

      def fetch_from_rubygems
        uri = URI(RUBYGEMS_API_URL)
        response = Net::HTTP.get_response(uri)
        return nil unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        data['version']
      rescue StandardError
        nil
      end

      def newer_version?(latest)
        Gem::Version.new(latest) > Gem::Version.new(VERSION)
      end

      def display_update_notification(latest)
        require 'tty-box'

        box = TTY::Box.frame(
          width: 60,
          padding: 1,
          align: :center,
          border: :light,
          style: {
            border: { fg: :yellow }
          }
        ) do
          [
            'A new version of moduloproject is available!',
            '',
            "Current version: #{VERSION}",
            "Latest version:  #{latest}",
            '',
            'Run `brew upgrade moduloproject` to update',
            'or `gem update moduloproject`'
          ].join("\n")
        end

        warn box
      end
    end
  end
end
