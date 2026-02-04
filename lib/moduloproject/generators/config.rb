# frozen_string_literal: true

module Moduloproject
  module Generators
    # Config generator creates application configuration files.
    # Migrated from Modulorails::Docker::ConfigGenerator.
    class Config < Base
      VERSION = 2

      GENERATED_FILES = %w[
        config/database.yml
        config/cable.yml
        config/puma.rb
      ].freeze

      # Generate application configuration files
      #
      # @return [Array<String>] List of generated file paths
      def generate
        return GENERATED_FILES if skip_generation?

        generated = []

        generated << create_database_config
        generated << create_cable_config
        generated << create_puma_config

        update_keepfile
        generated.compact
      end

      private

      def create_database_config
        return if context.sqlite3?

        content = render_template('config/database.yml.erb')
        write_file('config/database.yml', content, force: true)
      end

      def create_cable_config
        content = render_template('config/cable.yml.erb')
        write_file('config/cable.yml', content, force: options[:force])
      end

      def create_puma_config
        content = render_template('config/puma.rb.erb')
        write_file('config/puma.rb', content, force: options[:force])
      end
    end
  end
end
