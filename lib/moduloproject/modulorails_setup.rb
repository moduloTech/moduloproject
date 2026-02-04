# frozen_string_literal: true

require 'fileutils'

module Moduloproject
  # Sets up Modulorails gem in a newly created Rails project.
  # Adds the gem to Gemfile and creates the initializer.
  class ModulorailsSetup
    attr_reader :name, :options

    def initialize(name, options)
      @name = name
      @options = options
    end

    def execute
      puts 'Setting up Modulorails...'
      add_to_gemfile
      version = detect_version

      if version_1?(version)
        create_initializer
      else
        run_modulorails_install
      end

      fix_file_ownership
      puts 'Modulorails configured successfully!'
    end

    private

    def add_to_gemfile
      gemfile_path = File.join(name, 'Gemfile')
      return unless File.exist?(gemfile_path)

      content = File.read(gemfile_path)
      return if content.include?('modulorails')

      File.open(gemfile_path, 'a') do |f|
        f.puts
        f.puts '# Modulotech shared infrastructure'
        f.puts "gem 'modulorails'"
      end
    end

    def docker_image
      "ruby:#{options[:ruby]}-alpine"
    end

    def detect_version
      lockfile = File.join(name, 'Gemfile.lock')
      return nil unless File.exist?(lockfile)

      content = File.read(lockfile)
      match = content.match(/^\s+modulorails\s+\((\d+\.\d+(?:\.\d+)?)\)/)
      match ? match[1] : nil
    end

    def version_1?(version)
      return true if version.nil?

      major = version.split('.').first.to_i
      major < 2
    end

    def run_modulorails_install
      command = build_modulorails_docker_command
      success = system(command)
      raise 'Modulorails install failed' unless success
    end

    def build_modulorails_docker_command
      <<~CMD.gsub(/\s+/, ' ').strip
        docker run --rm
        -v "#{Dir.pwd}/#{name}:/app"
        -w /app
        -e HOME=/tmp
        #{docker_image}
        sh -c "
          apk add alpine-sdk yaml-dev nodejs npm > /dev/null 2>&1 &&
          bundle install --quiet &&
          bundle exec modulorails install
        "
      CMD
    end

    def fix_file_ownership
      return unless current_uid_gid

      system("docker run --rm -v \"#{Dir.pwd}/#{name}:/app\" #{docker_image} chown -R #{current_uid_gid} /app")
    end

    def current_uid_gid
      return @current_uid_gid if defined?(@current_uid_gid)

      uid = `id -u`.strip
      gid = `id -g`.strip
      @current_uid_gid = "#{uid}:#{gid}" if uid && gid && !uid.empty? && !gid.empty?
    end

    def create_initializer
      initializer_content = <<~RUBY
        # frozen_string_literal: true

        Modulorails.configure do |config|
          config.name '#{camelize(name)}'
          config.main_developer 'developer@modulotech.fr'
          config.project_manager 'manager@modulotech.fr'
          config.endpoint 'https://50cent.modulotech.fr/api/projects'
          config.api_key ''
        end
      RUBY

      path = File.join(name, 'config', 'initializers', 'modulorails.rb')
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, initializer_content)
    end

    def camelize(string)
      string.to_s.split(/[_-]/).map(&:capitalize).join
    end
  end
end
