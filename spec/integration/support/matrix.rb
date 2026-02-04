# frozen_string_literal: true

module IntegrationTests
  module Matrix
    RAILS_VERSIONS = %w[7.2 8.0 8.1].freeze
    DATABASES = %w[postgresql mysql2 sqlite3].freeze
    FRONTENDS = %w[vue hotwire].freeze
    ACTIVE_JOBS = %w[sidekiq solid_queue].freeze
    ACTION_CABLES = %w[redis solid_cable].freeze
    RAILS_CACHES = %w[redis solid_cache].freeze

    RUBY_VERSIONS_FOR_RAILS = {
      '7.2' => %w[3.1 3.2 3.3 3.4].freeze,
      '8.0' => %w[3.2 3.3 3.4].freeze,
      '8.1' => %w[3.2 3.3 3.4 4].freeze
    }.freeze

    SOLID_BACKENDS = %w[solid_queue solid_cable solid_cache].freeze

    Combination = Struct.new(
      :rails, :ruby, :database, :frontend, :active_job, :action_cable, :rails_cache,
      keyword_init: true
    ) do
      def label
        aj_label = active_job.tr('_', '-')
        ac_label = action_cable.tr('_', '-')
        rc_label = rails_cache.tr('_', '-')
        ruby_label = "ruby#{ruby.delete('.')}"
        "rails#{rails.delete('.')}_#{ruby_label}_#{database}_#{frontend}_#{aj_label}_#{ac_label}_#{rc_label}"
      end

      def app_name
        "app-#{label}".tr('_', '-')
      end

      def options_hash
        {
          rails: rails,
          ruby: ruby,
          database: database,
          frontend: frontend,
          active_job: active_job,
          action_cable: action_cable,
          rails_cache: rails_cache
        }
      end

      def ruby_version
        ruby
      end

      def uses_redis?
        active_job == 'sidekiq' || action_cable == 'redis' || rails_cache == 'redis'
      end

      def all_solid?
        SOLID_BACKENDS.include?(active_job) &&
          SOLID_BACKENDS.include?(action_cable) &&
          SOLID_BACKENDS.include?(rails_cache)
      end

      def all_non_solid?
        !SOLID_BACKENDS.include?(active_job) &&
          !SOLID_BACKENDS.include?(action_cable) &&
          !SOLID_BACKENDS.include?(rails_cache)
      end

      def mixed_solid?
        !all_solid? && !all_non_solid?
      end

      def supports_skip_solid?
        %w[8.0 8.1].include?(rails)
      end

      def skip_solid_passed?
        supports_skip_solid? && all_non_solid?
      end

      def needs_solid_cleanup?
        supports_skip_solid? && mixed_solid?
      end

      def solid_backend_gems
        return {} unless supports_skip_solid?

        gems = {}
        gems['solid_queue'] = 'solid_queue' if active_job == 'solid_queue'
        gems['solid_cable'] = 'solid_cable' if action_cable == 'solid_cable'
        gems['solid_cache'] = 'solid_cache' if rails_cache == 'solid_cache'
        gems
      end

      def solid_files
        return [] unless supports_skip_solid?

        %w[
          config/cache.yml
          config/queue.yml
          config/recurring.yml
          db/cache_schema.rb
          db/queue_schema.rb
          db/cable_schema.rb
        ]
      end
    end

    def self.all_combinations
      RAILS_VERSIONS.flat_map do |rails|
        RUBY_VERSIONS_FOR_RAILS[rails].flat_map do |ruby|
          DATABASES.flat_map do |db|
            FRONTENDS.flat_map do |fe|
              ACTIVE_JOBS.flat_map do |aj|
                ACTION_CABLES.flat_map do |ac|
                  RAILS_CACHES.map do |rc|
                    Combination.new(
                      rails: rails, ruby: ruby, database: db, frontend: fe,
                      active_job: aj, action_cable: ac, rails_cache: rc
                    )
                  end
                end
              end
            end
          end
        end
      end
    end

    def self.combinations_for_rails(version)
      all_combinations.select { |c| c.rails == version }
    end
  end
end
