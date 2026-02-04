# frozen_string_literal: true

require 'json'

module Moduloproject
  # Sets up Vite in a Rails project for the vue stack.
  # Adds vite_rails gem and runs the vite install command via Docker.
  class ViteSetup
    attr_reader :name, :options

    def initialize(name, options)
      @name = name
      @options = options
    end

    def execute
      return unless options[:frontend] == 'vue'

      puts 'Setting up Vite...'
      add_to_gemfile
      run_vite_install
      ensure_bin_vite
      ensure_bin_dev_with_foreman
      configure_package_scripts
      puts 'Vite configured successfully!'
    end

    private

    def add_to_gemfile
      gemfile_path = File.join(name, 'Gemfile')
      return unless File.exist?(gemfile_path)

      content = File.read(gemfile_path)
      return if content.include?('vite_rails')

      File.open(gemfile_path, 'a') do |f|
        f.puts
        f.puts '# Vite for modern JavaScript bundling'
        f.puts "gem 'vite_rails'"
      end
    end

    def run_vite_install
      command = build_docker_command

      success = system(command)
      raise 'Vite installation failed. Please check Docker is running.' unless success

      fix_file_ownership
    end

    def build_docker_command
      <<~CMD.gsub(/\s+/, ' ').strip
        docker run --rm
        -v "#{Dir.pwd}/#{name}:/app"
        -w /app
        -e HOME=/tmp
        #{docker_image}
        sh -c "
          apk add alpine-sdk yaml-dev nodejs npm #{database_packages} > /dev/null 2>&1 &&
          bundle install --quiet &&
          bundle exec vite install &&
          bundle binstubs vite_ruby --force &&
          npm install #{vue_dependencies.join(' ')} &&
          npm install -D #{vue_dev_dependencies.join(' ')}
        "
      CMD
    end

    def docker_image
      "ruby:#{options[:ruby]}-alpine"
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

    def vue_dependencies
      %w[
        @vueuse/core
        vue
        vue-i18n
        vue-multiselect
        vue-router
      ]
    end

    def vue_dev_dependencies
      %w[
        @vitejs/plugin-vue
        @eslint/js@^9
        @testing-library/vue
        @vitest/coverage-v8
        @vue/test-utils
        eslint@^9
        eslint-plugin-vue
        happy-dom
        vite-svg-loader
        vitest
      ]
    end

    def configure_package_scripts
      package_json_path = File.join(name, 'package.json')
      return unless File.exist?(package_json_path)

      pkg = JSON.parse(File.read(package_json_path))
      pkg['scripts'] = (pkg['scripts'] || {}).merge(vue_scripts)
      File.write(package_json_path, "#{JSON.pretty_generate(pkg)}\n")
    end

    def vue_scripts
      {
        'build' => 'bin/vite build',
        'dev' => 'bin/vite',
        'lint' => 'npx eslint app/frontend',
        'test' => 'vitest run',
        'test:watch' => 'vitest',
        'test:coverage' => 'vitest run --coverage'
      }
    end

    def ensure_bin_vite
      bin_vite_path = File.join(name, 'bin/vite')
      return if File.exist?(bin_vite_path)

      puts '  Creating missing bin/vite (Ruby 4 / vite_ruby compatibility workaround)...'
      FileUtils.mkdir_p(File.dirname(bin_vite_path))
      File.write(bin_vite_path, <<~RUBY)
        #!/usr/bin/env ruby
        require "vite_ruby"
        ViteRuby.run
      RUBY
      File.chmod(0o755, bin_vite_path)
    end

    def ensure_bin_dev_with_foreman
      bin_dev_path = File.join(name, 'bin/dev')
      content = File.exist?(bin_dev_path) ? File.read(bin_dev_path) : ''
      return if content.include?('foreman')

      puts '  Updating bin/dev to use foreman...'
      File.write(bin_dev_path, <<~SH)
        #!/usr/bin/env sh

        if ! gem list foreman -i --silent; then
          echo "Installing foreman..."
          gem install foreman
        fi

        exec foreman start -f Procfile.dev "$@"
      SH
      File.chmod(0o755, bin_dev_path)
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
  end
end
