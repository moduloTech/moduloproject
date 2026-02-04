# frozen_string_literal: true

# Integration test spec_helper.
# NO SimpleCov - integration tests do not count toward coverage.

require 'rspec'
require 'yaml'
require 'json'
require 'open3'
require 'stringio'
require 'fileutils'

# Load the gem and its runtime dependencies
require 'moduloproject'
require 'tty-box'

# Load integration support files
require_relative 'support/matrix'
require_relative 'support/docker_guard'
require_relative 'support/project_workspace'

# Load custom matchers
Dir[File.join(__dir__, 'support/matchers/**/*.rb')].each { |f| require f }

# Load shared examples
Dir[File.join(__dir__, 'shared_examples/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.filter_run_including integration: true

  # Run in defined order (parallel_tests handles distribution)
  config.order = :defined

  # Disable warnings for cleaner output
  config.warnings = false

  config.formatter = :progress

  # When running in parallel, write per-worker JSON results
  if ENV['INTEGRATION_RESULTS_DIR']
    results_dir = ENV['INTEGRATION_RESULTS_DIR']
    FileUtils.mkdir_p(results_dir)
    worker = ENV.fetch('TEST_ENV_NUMBER', '1').to_s
    config.add_formatter('json', File.join(results_dir, "worker_#{worker}.json"))
  end

  # Expect syntax only
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
