# frozen_string_literal: true

module Moduloproject
  module Generators
    # GitLab CI generator creates .gitlab-ci.yml and bin/test script.
    # Migrated from Modulorails::GitlabciGenerator.
    class GitlabCi < Base
      VERSION = 3

      GENERATED_FILES = %w[
        .gitlab-ci.yml
        bin/test
      ].freeze

      # Generate GitLab CI configuration files
      #
      # @return [Array<String>] List of generated file paths
      def generate
        return GENERATED_FILES if skip_generation?

        generated = []

        generated << create_gitlab_ci
        generated << create_test_script
        generated << create_ci_runner
        generated += create_deploy_configs

        update_keepfile
        generated.compact
      end

      private

      def create_gitlab_ci
        content = render_template('ci/.gitlab-ci.yml.erb')
        write_file('.gitlab-ci.yml', content, force: options[:force])
      end

      def create_test_script
        content = render_template('ci/bin_test.sh.erb')
        write_file('bin/test', content, force: options[:force], executable: true)
      end

      def create_ci_runner
        if context.rails_version_gte?('8.1')
          content = render_template('ci/config_ci.rb.erb')
          write_file('config/ci.rb', content, force: true)
        else
          content = render_template('ci/bin_ci.rb.erb')
          write_file('bin/ci', content, force: options[:force], executable: true)
        end
      end

      def create_deploy_configs
        configs = []
        configs << create_deploy_config('production', context.production_url)
        configs << create_deploy_config('staging', context.staging_url)
        configs << create_deploy_config('review', context.review_base_url)
        configs.compact
      end

      def create_deploy_config(environment, url)
        return if url.nil? || url.to_s.empty?

        content = render_template("config/deploy/#{environment}.yaml.erb")
        write_file("config/deploy/#{environment}.yaml", content, force: options[:force])
      end
    end
  end
end
