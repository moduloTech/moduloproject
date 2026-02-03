# frozen_string_literal: true

module Moduloproject
  module Generators
    # Devcontainer generator creates VS Code devcontainer configuration.
    # Migrated from Modulorails::Docker::DevcontainerGenerator.
    class Devcontainer < Base
      VERSION = 1

      GENERATED_FILES = %w[
        .devcontainer/devcontainer.json
        .devcontainer/compose.yml
        .devcontainer/Dockerfile
      ].freeze

      # Generate devcontainer configuration files
      #
      # @return [Array<String>] List of generated file paths
      def generate
        return GENERATED_FILES if skip_generation?

        generated = []

        generated << create_devcontainer_json
        generated << create_compose
        generated << create_dockerfile

        update_keepfile
        generated.compact
      end

      private

      def create_devcontainer_json
        content = render_template('devcontainer/devcontainer.json.erb')
        write_file('.devcontainer/devcontainer.json', content, force: options[:force])
      end

      def create_compose
        content = render_template('devcontainer/compose.yml.erb')
        write_file('.devcontainer/compose.yml', content, force: options[:force])
      end

      def create_dockerfile
        content = render_template('devcontainer/Dockerfile.erb')
        write_file('.devcontainer/Dockerfile', content, force: options[:force])
      end
    end
  end
end
