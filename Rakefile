# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Default spec task excludes integration tests
RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/integration/**/*_spec.rb'
end

RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :integration do
  desc 'Generate integration spec files from the combination matrix'
  task :generate do
    ruby 'script/generate_integration_specs.rb'
  end

  # Use .rspec-integration to avoid loading SimpleCov from the main .rspec
  integration_rspec = 'bundle exec rspec --options .rspec-integration'
  results_dir = 'tmp/integration'

  desc 'Run all integration tests sequentially'
  task :test do
    sh "#{integration_rspec} --format progress spec/integration/combinations/"
  end

  desc 'Run integration tests in parallel (default: number of CPUs)'
  task :parallel, [:count] do |_t, args|
    FileUtils.mkdir_p(results_dir)
    count = args[:count] || ''
    count_flag = count.empty? ? '' : "-n #{count}"
    log_file = File.join(results_dir, 'results.log')

    sh({ 'INTEGRATION_RESULTS_DIR' => results_dir },
       "bundle exec parallel_rspec #{count_flag} " \
       '--verbose-process-command ' \
       "-o '--options .rspec-integration --format progress' " \
       "spec/integration/combinations/ 2>&1 | tee #{log_file}")
  end

  desc 'Show results summary from the last parallel run'
  task :results do
    require 'json'
    dir = results_dir
    json_files = Dir.glob(File.join(dir, 'worker_*.json'))
    abort "No result files found in #{dir}/" if json_files.empty?

    total_examples = 0
    total_failures = 0
    total_pending = 0
    total_duration = 0.0
    failures = []

    json_files.each do |file|
      raw = File.read(file)
      next if raw.strip.empty?

      data = JSON.parse(raw)
      summary = data['summary']
      total_examples += summary['example_count']
      total_failures += summary['failure_count']
      total_pending += summary['pending_count']
      total_duration += summary['duration']

      data['examples'].select { |e| e['status'] == 'failed' }.each do |ex|
        failures << {
          'file' => ex['file_path'],
          'description' => ex['full_description'],
          'message' => ex.dig('exception', 'message')
        }
      end
    end

    puts "Integration test results (#{json_files.size} workers)"
    puts '=' * 60
    puts "  Examples:  #{total_examples}"
    puts "  Failures:  #{total_failures}"
    puts "  Pending:   #{total_pending}"
    puts "  Duration:  #{total_duration.round(1)}s"
    puts

    if failures.empty?
      puts 'All tests passed.'
    else
      puts 'Failed examples:'
      puts
      failures.each do |f|
        puts "  #{f['description']}"
        puts "    #{f['file']}"
        puts "    #{f['message']&.lines&.first&.strip}"
        puts
      end
    end
  end

  desc 'Run a single integration test by label'
  task :single, [:label] do |_t, args|
    label = args[:label]
    abort 'Usage: rake integration:single[label]' unless label

    spec_file = "spec/integration/combinations/#{label}_spec.rb"
    abort "Spec file not found: #{spec_file}" unless File.exist?(spec_file)

    sh "#{integration_rspec} --format documentation #{spec_file}"
  end

  desc 'Run integration tests for a specific Rails version'
  task :rails_version, [:version] do |_t, args|
    version = args[:version]
    abort 'Usage: rake integration:rails_version[7.2]' unless version

    pattern = "spec/integration/combinations/rails#{version.delete('.')}*_spec.rb"
    files = Dir.glob(pattern)
    abort "No spec files found for Rails #{version}" if files.empty?

    sh "#{integration_rspec} --format progress #{files.join(' ')}"
  end

  desc 'Clean up integration test workspaces'
  task :clean do
    require_relative 'spec/integration/support/project_workspace'
    IntegrationTests::ProjectWorkspace.cleanup_all
    FileUtils.rm_rf(results_dir)
    puts "Cleaned up workspaces and #{results_dir}/"
  end
end
