# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'
require 'simplecov_json_formatter'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::HTMLFormatter, # dev local
                                                                 SimpleCov::Formatter::LcovFormatter,  # GitHub/CI
                                                                 SimpleCov::Formatter::JSONFormatter   # Claude Code
                                                               ])

SimpleCov.start do
  add_filter '/spec/'
  add_group 'Generators', 'lib/moduloproject/generators'
  add_group 'Core', 'lib/moduloproject'
  enable_coverage :branch
  minimum_coverage 90
end

require 'bundler/setup'
require 'fileutils'
require 'tmpdir'
require 'yaml'

require 'moduloproject'
require 'moduloproject/cli'
require 'moduloproject/context'
require 'moduloproject/template_engine'
require 'moduloproject/generators'
require 'moduloproject/version_check'
require 'moduloproject/commands/new'
require 'moduloproject/rails_generator'
require 'moduloproject/modulorails_setup'
require 'moduloproject/vite_setup'
require 'moduloproject/recipe'
require 'moduloproject/backends/active_job'
require 'moduloproject/backends/active_job/sidekiq'
require 'moduloproject/backends/active_job/solid_queue'
require 'moduloproject/backends/action_cable'
require 'moduloproject/backends/action_cable/redis'
require 'moduloproject/backends/action_cable/solid_cable'
require 'moduloproject/backends/rails_cache'
require 'moduloproject/backends/rails_cache/redis'
require 'moduloproject/backends/rails_cache/solid_cache'
require 'moduloproject/setup/active_job_setup'
require 'moduloproject/setup/action_cable_setup'
require 'moduloproject/setup/rails_cache_setup'
require 'moduloproject/setup/brakeman_setup'
require 'moduloproject/setup/solid_cleanup'
require 'moduloproject/ticketing_config'
require 'webmock/rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
