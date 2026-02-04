# frozen_string_literal: true

module Moduloproject
  module Backends
    module ActiveJob
      # Sidekiq strategy for Active Job.
      # Configures queue_adapter = :sidekiq and adds sidekiq gem.
      class Sidekiq
        attr_reader :name, :options

        def initialize(name, options)
          @name = name
          @options = options
        end

        def apply
          configure_queue_adapter
          add_gem_to_gemfile
        end

        def gem_name
          'sidekiq'
        end

        def adapter_name
          :sidekiq
        end

        private

        def configure_queue_adapter
          application_rb = File.join(name, 'config', 'application.rb')
          return unless File.exist?(application_rb)

          content = File.read(application_rb)

          content = if content.include?('config.active_job.queue_adapter')
                      content.gsub(
                        /config\.active_job\.queue_adapter\s*=\s*:\w+/,
                        'config.active_job.queue_adapter = :sidekiq'
                      )
                    else
                      content.gsub(
                        /(\n\s*end\s*\nend\s*\z)/,
                        "\n    config.active_job.queue_adapter = :sidekiq\\1"
                      )
                    end

          File.write(application_rb, content)
        end

        def add_gem_to_gemfile
          gemfile_path = File.join(name, 'Gemfile')
          return unless File.exist?(gemfile_path)

          content = File.read(gemfile_path)
          return if content.include?("gem 'sidekiq'") || content.include?('gem "sidekiq"')

          content += "\n# Sidekiq for background jobs\ngem 'sidekiq'\ngem 'redis'\n"
          File.write(gemfile_path, content)
        end
      end

      register('sidekiq', Sidekiq)
    end
  end
end
