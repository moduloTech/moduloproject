# frozen_string_literal: true

require 'thor'

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
    option :template, type: :string, desc: 'Template to use (default, api, etc.)'
    option :ruby_version, type: :string, desc: 'Ruby version to use'
    option :rails_version, type: :string, desc: 'Rails version to use'
    def new(app_name)
      puts "Creating new project: #{app_name}"
      puts 'Not implemented yet'
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
