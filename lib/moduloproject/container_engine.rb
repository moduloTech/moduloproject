# frozen_string_literal: true

module Moduloproject
  # Resolves the container engine used to run Ruby/Rails tooling: Docker or Podman.
  module ContainerEngine
    module_function

    # CONTAINER_ENGINE if set, else docker when its daemon answers, else podman when installed.
    def command
      @command ||= ENV.fetch('CONTAINER_ENGINE') { detect }
    end

    # Rootless Podman already maps the container's root to the current user, so files it
    # creates need no chown (a chown to the host uid would hand them to a subordinate uid).
    def rootless_podman?
      return @rootless_podman if defined?(@rootless_podman)

      @rootless_podman = command == 'podman' &&
                         `podman info --format {{.Host.Security.Rootless}} 2>/dev/null`.strip == 'true'
    end

    # Fully qualified image name, so that Podman does not depend on short-name resolution.
    def image(name)
      first, rest = name.split('/', 2)
      return "docker.io/library/#{name}" if rest.nil?
      return name if first.include?('.') || first.include?(':') || first == 'localhost'

      "docker.io/#{name}"
    end

    def reset!
      @command = nil
      remove_instance_variable(:@rootless_podman) if defined?(@rootless_podman)
    end

    def detect
      return 'docker' if system('docker info', out: File::NULL, err: File::NULL)
      return 'podman' if system('podman --version', out: File::NULL, err: File::NULL)

      'docker'
    end
  end
end
