# frozen_string_literal: true

module Moduloproject
  module Backends
    module ActionCable
      # Redis strategy for Action Cable.
      # Creates cable.yml with Redis adapter for all environments.
      class Redis
        attr_reader :name, :options

        def initialize(name, options)
          @name = name
          @options = options
        end

        def apply
          write_cable_yml
          add_gem_to_gemfile
        end

        def gem_name
          'redis'
        end

        def adapter_name
          :redis
        end

        private

        def write_cable_yml
          cable_yml = File.join(name, 'config', 'cable.yml')
          app_name = name.tr('-', '_')

          content = <<~YAML
            development:
              adapter: redis
              url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
              channel_prefix: #{app_name}_development

            test:
              adapter: redis
              url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
              channel_prefix: #{app_name}_test

            production:
              adapter: redis
              url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
              channel_prefix: #{app_name}_production
          YAML

          File.write(cable_yml, content)
        end

        def add_gem_to_gemfile
          gemfile_path = File.join(name, 'Gemfile')
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?("gem 'redis'") || content.include?('gem "redis"')

          content += "\n# Redis for Action Cable\ngem 'redis'\n"
          File.write(gemfile_path, content)
        end
      end

      register('redis', Redis)
    end
  end
end
