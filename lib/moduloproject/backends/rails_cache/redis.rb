# frozen_string_literal: true

module Moduloproject
  module Backends
    module RailsCache
      # Redis strategy for Rails cache.
      # Configures redis_cache_store and adds redis gem.
      class Redis
        attr_reader :name, :options

        def initialize(name, options)
          @name = name
          @options = options
        end

        def apply
          remove_solid_cache_store
          configure_redis_cache_store
          add_gem_to_gemfile
        end

        def gem_name
          'redis'
        end

        def store_name
          :redis_cache_store
        end

        private

        def remove_solid_cache_store
          production_rb = File.join(name, 'config', 'environments', 'production.rb')
          return unless File.exist?(production_rb)

          content = File.read(production_rb)
          content = content.gsub(/^\s*config\.cache_store\s*=\s*:solid_cache_store.*\n/, '')
          File.write(production_rb, content)
        end

        def configure_redis_cache_store
          application_rb = File.join(name, 'config', 'application.rb')
          return unless File.exist?(application_rb)

          content = File.read(application_rb)
          return if content.include?(':redis_cache_store')

          content = content.gsub(
            /(\n\s*end\s*\nend\s*\z)/,
            "\n    config.cache_store = :redis_cache_store, { url: ENV.fetch(\"REDIS_URL\", \"redis://localhost:6379/1\") }\\1"
          )
          File.write(application_rb, content)
        end

        def add_gem_to_gemfile
          gemfile_path = File.join(name, 'Gemfile')
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?("gem 'redis'") || content.include?('gem "redis"')

          content += "\n# Redis for caching\ngem 'redis'\n"
          File.write(gemfile_path, content)
        end
      end

      register('redis', Redis)
    end
  end
end
