# Phase 4 - Command `new`

**Estimate:** 2 days

## Objectives

- Port current Bash logic to Ruby
- Implement project scaffolding
- Docker-based Rails generation

## CLI Interface

```bash
moduloproject new my-app \
  --ruby 4 \
  --rails 8.1 \
  --database postgresql \
  --frontend vue3 \
  --js-bundler vite
```

| Option | Default | Values |
|--------|---------|--------|
| `--ruby` | 4 | 4 |
| `--rails` | 8.1 | 8.1 |
| `--database` | postgresql | postgresql |
| `--frontend` | vue3 | vue3, none |
| `--js-bundler` | vite | vite, importmap |
| `--skip-docker` | false | - |

## Command Implementation

```ruby
# lib/moduloproject/commands/new.rb
module Moduloproject
  module Commands
    class New
      attr_reader :name, :options

      DEFAULTS = {
        ruby: "4",
        rails: "8.1",
        database: "postgresql",
        frontend: "vue3",
        js_bundler: "vite",
        skip_docker: false
      }.freeze

      def initialize(name, options = {})
        @name = name
        @options = DEFAULTS.merge(options)
      end

      def execute
        validate_name!
        validate_options!

        steps = [
          -> { create_project_directory },
          -> { generate_rails_app },
          -> { setup_modulorails },
          -> { generate_infrastructure },
          -> { setup_git },
          -> { display_success }
        ]

        steps.each(&:call)
      end

      private

      def validate_name!
        raise ArgumentError, "Project name required" if name.nil? || name.empty?
        raise ArgumentError, "Invalid project name: #{name}" unless name.match?(/\A[a-z][a-z0-9_-]*\z/)
      end

      def validate_options!
        # Only latest Rails for new projects
        unless options[:rails] == "8.1"
          raise ArgumentError, "Only Rails 8.1 is supported for new projects"
        end
      end

      def create_project_directory
        if Dir.exist?(name)
          raise ArgumentError, "Directory already exists: #{name}"
        end
        FileUtils.mkdir_p(name)
      end

      def generate_rails_app
        RailsGenerator.new(name, options).generate
      end

      def setup_modulorails
        # Add modulorails gem and configure
        ModulorailsSetup.new(name, options).execute
      end

      def generate_infrastructure
        context = build_context
        
        Generators.run_all(context) unless options[:skip_docker]
      end

      def setup_git
        Dir.chdir(name) do
          system("git init")
          system("git add .")
          system("git commit -m 'Initial commit via moduloproject'")
        end
      end

      def display_success
        puts TTY::Box.success(
          "Project #{name} created successfully!",
          "",
          "Next steps:",
          "  cd #{name}",
          "  docker compose up",
          padding: 1
        )
      end

      def build_context
        {
          project_name: name,
          project_root: File.expand_path(name),
          ruby_version: options[:ruby],
          rails_version: options[:rails],
          database: options[:database],
          frontend: options[:frontend],
          js_bundler: options[:js_bundler],
          mcp: default_mcp_config
        }
      end

      def default_mcp_config
        {
          datadog: true,
          gitlab: true,
          github: false,
          jira: false,
          confluence: false,
          notion: false
        }
      end
    end
  end
end
```

## Rails Generator (via Docker)

```ruby
# lib/moduloproject/rails_generator.rb
module Moduloproject
  class RailsGenerator
    DOCKER_IMAGE = "ruby:4".freeze

    def initialize(name, options)
      @name = name
      @options = options
    end

    def generate
      command = build_docker_command
      
      puts "Generating Rails application..."
      success = system(command)
      
      raise "Rails generation failed" unless success
    end

    private

    def build_docker_command
      rails_options = build_rails_options
      
      <<~CMD.squish
        docker run --rm
        -v "#{Dir.pwd}:/app"
        -w /app
        #{DOCKER_IMAGE}
        bash -c "
          gem install rails -v '~> #{@options[:rails]}' &&
          rails new #{@name} #{rails_options}
        "
      CMD
    end

    def build_rails_options
      opts = []
      opts << "--database=postgresql"
      opts << "--skip-test"  # We use RSpec
      opts << "--skip-system-test"
      
      case @options[:js_bundler]
      when "vite"
        opts << "--javascript=vite"
      when "importmap"
        opts << "--javascript=importmap"
      end

      opts << "--css=bootstrap" if @options[:frontend] == "vue3"
      
      opts.join(" ")
    end
  end
end
```

## Modulorails Setup

```ruby
# lib/moduloproject/modulorails_setup.rb
module Moduloproject
  class ModulorailsSetup
    def initialize(name, options)
      @name = name
      @options = options
    end

    def execute
      add_to_gemfile
      create_initializer
    end

    private

    def add_to_gemfile
      gemfile_path = File.join(@name, "Gemfile")
      content = File.read(gemfile_path)
      
      unless content.include?("modulorails")
        File.open(gemfile_path, "a") do |f|
          f.puts "\n# Modulotech shared infrastructure"
          f.puts "gem 'modulorails', '~> 2.0'"
        end
      end
    end

    def create_initializer
      initializer_content = <<~RUBY
        # frozen_string_literal: true

        Modulorails.configure do |config|
          config.application_name = '#{@name.camelize}'
          config.main_developer = 'developer@modulotech.fr'
          config.project_manager = 'manager@modulotech.fr'
          config.intranet_endpoint = 'https://50cent.modulotech.fr/api/projects'
          config.intranet_api_key = Rails.application.credentials.dig(:modulorails, :intranet_api_key)
          config.health_check_path = '/health'
        end
      RUBY

      path = File.join(@name, "config", "initializers", "modulorails.rb")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, initializer_content)
    end
  end
end
```

## CLI Integration

```ruby
# lib/moduloproject/cli.rb
module Moduloproject
  class CLI < Thor
    desc "new NAME", "Generate a new Rails project"
    option :ruby, type: :string, default: "4", desc: "Ruby version"
    option :rails, type: :string, default: "8.1", desc: "Rails version"
    option :database, type: :string, default: "postgresql", desc: "Database"
    option :frontend, type: :string, default: "vue3", desc: "Frontend framework"
    option :js_bundler, type: :string, default: "vite", desc: "JS bundler"
    option :skip_docker, type: :boolean, default: false, desc: "Skip Docker setup"
    def new(name)
      Commands::New.new(name, options.to_h.transform_keys(&:to_sym)).execute
    rescue ArgumentError => e
      error(e.message)
      exit 1
    end
  end
end
```

## Deliverables

- [ ] Command::New class
- [ ] RailsGenerator (Docker-based)
- [ ] ModulorailsSetup
- [ ] CLI option parsing
- [ ] Input validation
- [ ] Success/error output formatting
- [ ] Integration test (full project generation)
