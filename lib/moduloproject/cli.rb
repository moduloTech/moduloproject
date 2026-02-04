# frozen_string_literal: true

require 'thor'
require 'tty-box'

module Moduloproject
  class CLI < Thor
    def self.start(args = ARGV, config = {})
      VersionCheck.check_and_notify unless ENV['MODULOPROJECT_SKIP_VERSION_CHECK'] == '1'
      super
    end

    def self.exit_on_failure?
      true
    end

    desc 'version', 'Display the version of moduloproject'
    def version
      puts "moduloproject #{VERSION}"
    end
    map %w[-v --version] => :version

    desc 'new APP_NAME', 'Create a new Rails project with Modulotech conventions'
    option :ruby, type: :string, desc: 'Ruby version (resolved from recipe if omitted)'
    option :rails, type: :string,
                   desc: "Rails version (default: #{Recipe.latest_version}, supported: #{Recipe.available_versions.join(', ')})"
    option :database, type: :string, default: 'postgresql',
                      desc: 'Database adapter: postgresql, mysql2, sqlite3 (default: postgresql)'
    option :frontend, type: :string, default: 'vue',
                      desc: 'Frontend stack: vue (vite+vue3), hotwire (importmap+stimulus+bootstrap)'
    option :active_job, type: :string, desc: 'Active Job backend (e.g., sidekiq, solid_queue)'
    option :action_cable, type: :string, desc: 'Action Cable backend (e.g., redis, solid_cable)'
    option :rails_cache, type: :string, desc: 'Rails cache backend (e.g., redis, solid_cache)'
    option :skip_docker, type: :boolean, default: false, desc: 'Skip Docker/infrastructure setup'
    def new(app_name)
      Commands::New.new(app_name, options.to_h).execute
    rescue ArgumentError, Recipe::RecipeNotFoundError, Recipe::IncompatibleVersionError => e
      error_box = TTY::Box.error(e.message, padding: 1)
      puts error_box
      exit 1
    end

    desc 'sync', 'Synchronize project configuration with latest templates'
    option :dry_run, type: :boolean, default: false, desc: 'Show changes without applying them'
    option :force, type: :boolean, default: false, desc: 'Apply changes without confirmation'
    def sync
      puts 'Syncing project configuration...'
      puts 'Not implemented yet'
    end

    desc 'diff', 'Show differences between current project and templates'
    def diff
      puts 'Showing configuration diff...'
      puts 'Not implemented yet'
    end

    desc 'init', 'Initialize moduloproject in an existing Rails project'
    def init
      puts 'Initializing moduloproject...'
      puts 'Not implemented yet'
    end

    desc 'templates', 'List available templates'
    def templates
      puts 'Available templates:'
      puts 'Not implemented yet'
    end
  end
end
