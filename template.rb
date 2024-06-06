gem 'modulorails'
gem 'rails-i18n'
gem 'redis'

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
  unless File.read(gitignore_file).match?(/^\s\.idea/)
    append_to_file(gitignore_file, "\n.idea\n")
  end

  # Git commit
  git config: "--local user.email '#{ENV['GIT_EMAIL']}'"
  git config: "--local user.name '#{ENV['GIT_NAME']}'"
  git add: '.'
  git commit: '-am \'Initial commit\''
end
