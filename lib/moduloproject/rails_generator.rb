# frozen_string_literal: true

module Moduloproject
  # Generates a new Rails application using Docker.
  # This avoids the need for local Ruby/Rails installation.
  class RailsGenerator
    attr_reader :name, :options, :recipe

    def initialize(name, options, recipe:)
      @name = name
      @options = options
      @recipe = recipe
    end

    def generate
      command = build_docker_command

      puts 'Generating Rails application via Docker...'
      puts "(this may take a few minutes on first run)\n\n"

      success = system(command)

      raise 'Rails generation failed. Please check Docker is running.' unless success

      fix_file_ownership
      puts "\nRails application generated successfully!"
    end

    private

    def build_docker_command
      rails_options = build_rails_options

      <<~CMD.gsub(/\s+/, ' ').strip
        docker run --rm
        -v "#{Dir.pwd}:/app"
        -w /app
        -e HOME=/tmp
        #{docker_image}
        sh -c "
          apk add alpine-sdk yaml-dev nodejs npm tzdata #{database_packages} > /dev/null 2>&1 &&
          gem install rails -v '~> #{options[:rails]}' --no-document &&
          rails new #{name} #{rails_options}
        "
      CMD
    end

    def build_rails_options
      resolved = {
        active_job: options.fetch(:active_job) { recipe.backend_for(:active_job) },
        action_cable: options.fetch(:action_cable) { recipe.backend_for(:action_cable) },
        rails_cache: options.fetch(:rails_cache) { recipe.backend_for(:rails_cache) }
      }

      recipe.rails_options(
        frontend: options[:frontend],
        database: options[:database],
        resolved_backends: resolved
      ).join(' ')
    end

    def database_packages
      case options[:database]
      when 'mysql2'
        'mariadb-dev mariadb-client'
      when 'postgresql'
        'postgresql-dev postgresql-client'
      when 'sqlite3'
        'sqlite-dev'
      end
    end

    def docker_image
      "ruby:#{options[:ruby]}-alpine"
    end

    def fix_file_ownership
      # Docker creates files as root, fix ownership for the current user
      return unless current_uid_gid

      system("docker run --rm -v \"#{Dir.pwd}/#{name}:/app\" #{docker_image} chown -R #{current_uid_gid} /app")
    end

    def current_uid_gid
      return @current_uid_gid if defined?(@current_uid_gid)

      uid = `id -u`.strip
      gid = `id -g`.strip
      @current_uid_gid = "#{uid}:#{gid}" if uid && gid && !uid.empty? && !gid.empty?
    end
  end
end
