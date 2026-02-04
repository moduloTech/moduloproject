# frozen_string_literal: true

require 'open3'

module IntegrationTests
  module DockerGuard
    SKIP_MESSAGE = 'Docker is not available. Skipping integration test.'

    def self.docker_available?
      return @docker_available if defined?(@docker_available)

      @docker_available = begin
        _output, status = Open3.capture2e('docker', 'info')
        status.success?
      rescue Errno::ENOENT
        false
      end
    end

    def self.skip_unless_docker!(context)
      context.skip(SKIP_MESSAGE) unless docker_available?
    end
  end
end
