if ENV['MODULORAILS_BETA_MODE'] == 'true'
  gem 'modulorails', git: 'https://github.com/ModuloTech/modulorails.git', branch: 'development'
else
  gem 'modulorails'
end
gem 'rails-i18n'
gem 'redis'

# Lograge
gem 'lograge'
gem 'lograge-sql'
gem 'datadog-logging'
gem 'lograge-datadog-error-tracking'

project_name = ask('What is the common name of the project?')
main_developer = ask('What is the email of the project\'s main developer?')
project_manager = ask('What is the email of the project\'s manager?')
api_key = ask('Enter the 50cent API key:')
production_url = ask('Enter the production URL (leave blank if you do not know it):')
staging_url = ask('Enter the staging URL (leave blank if you do not know it):')
puts("A review URL is built like this at Modulotech https://review-\#{shortened_branch_name}-\#{ci_slug}.\#{review_base_url}:")
puts('review_base_url: dev.app.com')
puts('branch_name: 786-a_super_branch => shortened_branch_name: 786-a_sup')
puts('ci_slug: jzzham')
puts('|-> https://review-786-a_sup-jzzham.dev.app.com/')
review_base_url = ask('Enter the base of the review URL (leave blank if you do not know it):')

if [project_name, main_developer, project_manager, api_key].any?(&:blank?)
  raise 'Project name, main developer, project manager and 50cent API key are mandatory to configure Modulorails'
end

initializer 'modulorails.rb', <<~RUBY
  Modulorails.configure do |config|
    config.name '#{project_name}'
    config.main_developer '#{main_developer}'
    config.project_manager '#{project_manager}'
    config.endpoint 'https://50cent.modulotech.fr/api/projects'
    config.api_key '#{api_key}'
    #{review_base_url.present? ? "config.review_base_url '#{review_base_url}'" : ''}
    #{staging_url.present? ? "config.staging_url '#{staging_url}'" : ''}
    #{production_url.present? ? "config.production_url '#{production_url}'" : ''}
  end
RUBY

# Enable sassc-rails
gsub_file 'Gemfile', /^#\s*(gem\s+['"]sassc-rails['"].*$)/, '\1'

after_bundle do
  # Dockerization
  generate 'modulorails:docker'

  # Gitlab CI setup
  generate 'modulorails:gitlabci'

  # Rubocop setup
  generate 'modulorails:rubocop'

  # Standard configuration
  generate 'modulorails:moduloproject'

  # Lograge configuration
  add_file 'config/initializers/lograge.rb', <<~RUBY
    require 'lograge/sql/extension'

    Rails.application.configure do
      PARAMS_EXCEPTIONS ||= %w[controller action format id].freeze
      ENV_NAMES ||= %w[CONTENT_TYPE HTTP_ACCEPT HTTP_AUTHORIZATION].freeze

      # Enable lograge
      config.lograge.enabled = !Rails.env.development? && !Rails.env.test?

      # Format as JSON object
      config.lograge.formatter = Lograge::Formatters::Json.new

      # Ignore those actions
      config.lograge.ignore_actions = %w[
        HealthCheck::HealthCheckController#index
        Rails::HealthController#show
      ]

      # To keep sql default log in not prod mode
      config.lograge_sql.keep_default_active_record_log = Rails.env.development? || Rails.env.test?

      config.lograge_sql.extract_event = Proc.new do |event|
        { name: event.payload[:name], duration: event.duration.to_f.round(2), sql: event.payload[:sql] }
      end

      # Format the array of extracted events
      config.lograge_sql.formatter = Proc.new do |sql_queries|
        sql_queries
      end

      # Disables log coloration
      config.colorize_logging = Rails.env.development? || Rails.env.test?

      # Add some data to the log
      config.lograge.custom_payload do |controller|
        response = controller.response
        user = begin
                 controller.send(:current_user)
               rescue StandardError
                 nil
               end

        # If response is JSON, we want to get it as Hash
        # Datadog can handle a maximum of 256k bytes, so to not truncat the log, we limit response size to 64k
        parsed_response = if response.body.present? && response.headers['Content-Type']&.match(%r{application/json}) && response.body.size < 64_000
                            begin
                              JSON.parse(response.body)
                            rescue StandardError
                              nil
                            end
                          end

        # Get all the parameters (permitted or not) as a Hash
        params = controller.params.except(*PARAMS_EXCEPTIONS).to_unsafe_h

        {
          request_id: controller.request.request_id,
          time:       Time.zone.now.iso8601,
          headers:    controller.request.headers.env.select { |k, _| k =~ /^HTTP_X_/ || ENV_NAMES.include?(k) },
          params:     params,
          response:   parsed_response,
          user:       DatadogUserFormatter.call(user)
        }
      end

      # Configure logging of exceptions to the correct fields
      config.lograge.custom_options = Lograge::Datadog::Error::Tracking
    end
  RUBY

  add_file 'app/classes/datadog_user_formatter.rb', <<~RUBY
    # frozen_string_literal: true

    class DatadogUserFormatter

      def self.call(user)
        return if user.nil?

        {
          id:       user.id,
          username: user.id
        }
      end

    end
  RUBY
  puts('Please take a look at `config/initializers/lograge.rb` and `app/classes/datadog_user_formatter.rb` to customize them to your needs.')

  # ApplicationService creation
  add_file 'app/services/application_service.rb', <<~RUBY
    class ApplicationService < ::Modulorails::BaseService
    end
  RUBY

  # r.sh
  add_file 'r.sh', <<~SH
    #!/bin/sh

    echo "Reseting migrations..."
    bundle exec rake db:migrate:reset || exit 1
    echo "Seeding database..."
    bundle exec rake db:seed || exit 1
    echo "Done !"
  SH
  chmod 'r.sh', 0o755

  # Fix rubocop issues
  run 'rubocop -a'

  # Add .idea to .gitignore
  gitignore_file = '.gitignore'
  append_to_file(gitignore_file, "\n.idea\n") unless File.read(gitignore_file).match?(/^\s\.idea/)

  # Git commit
  git add: '.'
  git commit: '-am \'Initial commit\''
end
