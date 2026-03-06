# frozen_string_literal: true

require 'fileutils'

module Moduloproject
  module Commands
    # Command to create a new Rails project with Modulotech conventions.
    # Uses Docker to generate the Rails application and sets up all infrastructure.
    class New
      attr_reader :name, :options

      DEFAULTS = {
        database: 'postgresql',
        frontend: 'vue',
        skip_docker: false
      }.freeze

      VALID_DATABASES = %w[postgresql mysql2 sqlite3].freeze
      VALID_FRONTENDS = %w[vue hotwire].freeze
      NAME_PATTERN = /\A[a-z][a-z0-9_-]*\z/

      def initialize(name, options = {})
        @name = name
        @options = DEFAULTS.merge(symbolize_keys(options))
      end

      def execute
        validate_name!
        load_recipe!
        resolve_defaults_from_recipe!
        validate_options!

        steps = [
          -> { configure_ticketing },
          -> { create_project_directory },
          -> { generate_rails_app },
          -> { setup_active_job },
          -> { setup_action_cable },
          -> { setup_rails_cache },
          -> { cleanup_solid },
          -> { setup_modulorails },
          -> { setup_brakeman },
          -> { setup_vite },
          -> { generate_infrastructure },
          -> { setup_git },
          -> { display_success }
        ]

        steps.each(&:call)
      end

      private

      def symbolize_keys(hash)
        hash.transform_keys(&:to_sym)
      end

      def load_recipe!
        options[:rails] ||= Recipe.latest_version
        @recipe = Recipe.load(options[:rails])
      rescue Recipe::RecipeNotFoundError => e
        raise ArgumentError, e.message
      end

      def resolve_defaults_from_recipe!
        options[:ruby] ||= @recipe.default_ruby
      end

      def validate_name!
        raise ArgumentError, 'Project name required' if name.nil? || name.empty?
        raise ArgumentError, "Invalid project name: #{name}" unless name.match?(NAME_PATTERN)
      end

      def validate_options!
        validate_ruby_version!
        validate_database!
        validate_frontend!
        validate_backends!
      end

      def validate_ruby_version!
        @recipe.validate_ruby!(options[:ruby])
      rescue Recipe::IncompatibleVersionError => e
        raise ArgumentError, e.message
      end

      def validate_database!
        return if VALID_DATABASES.include?(options[:database])

        raise ArgumentError, "Invalid database: #{options[:database]}. Valid options: #{VALID_DATABASES.join(', ')}"
      end

      def validate_frontend!
        return if VALID_FRONTENDS.include?(options[:frontend])

        raise ArgumentError, "Invalid frontend: #{options[:frontend]}. Valid options: #{VALID_FRONTENDS.join(', ')}"
      end

      def validate_backends!
        %i[active_job action_cable rails_cache].each do |concern|
          next unless options[concern]

          available = @recipe.available_backends_for(concern)
          next if available.include?(options[concern])

          raise ArgumentError, "Invalid #{concern} backend: #{options[concern]}. Valid options: #{available.join(', ')}"
        end
      end

      def configure_ticketing
        @ticketing_config = TicketingConfig.resolve(options)
      end

      def create_project_directory
        raise ArgumentError, "Directory already exists: #{name}" if Dir.exist?(name)

        puts "Creating project directory: #{name}"
        FileUtils.mkdir_p(name)
      end

      def generate_rails_app
        RailsGenerator.new(name, options, recipe: @recipe).generate
      end

      def setup_active_job
        Setup::ActiveJobSetup.new(name, options, recipe: @recipe).execute
      end

      def setup_action_cable
        Setup::ActionCableSetup.new(name, options, recipe: @recipe).execute
      end

      def setup_rails_cache
        Setup::RailsCacheSetup.new(name, options, recipe: @recipe).execute
      end

      def cleanup_solid
        Setup::SolidCleanup.new(name, options, recipe: @recipe).execute(resolved_backends: resolved_backends)
      end

      def setup_modulorails
        ModulorailsSetup.new(name, options).execute
      end

      def setup_brakeman
        Setup::BrakemanSetup.new(name, options).execute
      end

      def setup_vite
        ViteSetup.new(name, options).execute
      end

      def generate_infrastructure
        return if options[:skip_docker]

        puts 'Generating infrastructure files...'
        context = build_context
        Generators.run_all(context,
                           verbose: true,
                           ticketing: @ticketing_config)
      end

      def setup_git
        puts 'Initializing git repository...'
        Dir.chdir(name) do
          system('git init -q')
          system('git add .')
          system('git', 'commit', '-q', '-m', commit_message)
        end
      end

      def commit_message
        backends = resolved_backends

        lines = [
          'Initial commit via moduloproject',
          '',
          'Configuration:',
          "  Ruby: #{options[:ruby]}",
          "  Rails: #{options[:rails]}",
          "  Database: #{options[:database]}",
          "  Frontend: #{options[:frontend]}",
          "  Active Job: #{backends[:active_job]}",
          "  Action Cable: #{backends[:action_cable]}",
          "  Rails Cache: #{backends[:rails_cache]}"
        ]

        lines.join("\n")
      end

      def display_success
        box_content = [
          "Project #{name} created successfully!",
          '',
          'Next steps:',
          "  cd #{name}",
          '  bin/dc up'
        ]

        if @ticketing_config&.enabled?
          box_content << ''
          box_content << 'MCP ticketing server configured.'
          box_content << 'Run: cd .claude/mcp-servers/ticket-ops && npm install'
        end

        puts
        puts TTY::Box.success(box_content.join("\n"), padding: 1)
      end

      def build_context
        Context.new(
          project_name: name,
          project_root: File.expand_path(name),
          ruby_version: options[:ruby],
          rails_version: "#{options[:rails]}.0",
          adapter: options[:database],
          js_engine: js_engine_symbol,
          frontend: options[:frontend],
          uses_redis: resolved_backends.values.any? { |b| %w[redis sidekiq].include?(b.to_s) },
          active_job_backend: resolved_backends[:active_job]
        )
      end

      def js_engine_symbol
        options[:frontend] == 'vue' ? :vite : :importmap
      end

      def resolved_backends
        {
          active_job: options.fetch(:active_job) { @recipe.backend_for(:active_job) },
          action_cable: options.fetch(:action_cable) { @recipe.backend_for(:action_cable) },
          rails_cache: options.fetch(:rails_cache) { @recipe.backend_for(:rails_cache) }
        }
      end
    end
  end
end
