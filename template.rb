gem 'modulorails'

project_name = ask('What is the common name of the project?')
main_developer = ask('What is the email of the project\'s main developer?')
project_manager = ask('What is the email of the project\'s manager?')
api_key = ask('Enter the 50cent API key:')

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
  end
RUBY

after_bundle do
  # Dockerization
  generate 'modulorails:docker'

  # Gitlab CI setup
  generate 'modulorails:gitlabci'

  # Rubocop setup
  generate 'modulorails:rubocop'

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

  # Git commit
  git config: "--local user.email '#{ENV['GIT_EMAIL']}'"
  git config: "--local user.name '#{ENV['GIT_NAME']}'"
  git add: '.'
  git commit: '-am \'Initial commit\''
end
