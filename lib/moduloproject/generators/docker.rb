# frozen_string_literal: true

module Moduloproject
  module Generators
    # Docker generator creates production Dockerfile, .dockerignore, and entrypoint script.
    # Migrated from Modulorails::Docker::DockerfileGenerator and EntrypointGenerator.
    class Docker < Base
      VERSION = 2

      GENERATED_FILES = %w[
        Dockerfile
        .dockerignore
        bin/docker-entrypoint
      ].freeze

      # Generate Docker configuration files
      #
      # @return [Array<String>] List of generated file paths
      def generate
        return GENERATED_FILES if skip_generation?

        generated = []

        generated << create_dockerfile
        generated << create_dockerignore
        generated << create_entrypoint

        update_keepfile
        generated.compact
      end

      private

      def create_dockerfile
        content = render_template('docker/Dockerfile.prod.erb')
        write_file('Dockerfile', content, force: options[:force])
      end

      def create_dockerignore
        content = render_template('docker/dockerignore.erb')
        write_file('.dockerignore', content, force: options[:force])
      end

      def create_entrypoint
        content = render_template('docker/entrypoint.sh.erb')
        write_file('bin/docker-entrypoint', content, force: options[:force], executable: true)
      end
    end
  end
end
