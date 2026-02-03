# frozen_string_literal: true

module Moduloproject
  module Generators
    # Git Hooks generator creates Docker helper scripts and git hooks.
    # Migrated from Modulorails::GithooksGenerator.
    class GitHooks < Base
      VERSION = 2

      GENERATED_FILES = %w[
        bin/dc
        bin/dcr
        bin/refresh_generations
        .git/hooks/post-rewrite
        .git/hooks/pre-merge-commit
        .gitattributes
      ].freeze

      # Generate git hooks and helper scripts
      #
      # @return [Array<String>] List of generated file paths
      def generate
        return GENERATED_FILES if skip_generation?

        generated = []

        generated << create_dc_script
        generated << create_dcr_script
        generated << create_refresh_generations
        generated += create_git_hooks
        generated << create_gitattributes

        update_keepfile
        generated.compact
      end

      private

      def create_dc_script
        content = render_template('git_hooks/dc.sh.erb')
        write_file('bin/dc', content, force: options[:force], executable: true)
      end

      def create_dcr_script
        content = render_template('git_hooks/dcr.sh.erb')
        write_file('bin/dcr', content, force: options[:force], executable: true)
      end

      def create_refresh_generations
        content = render_template('git_hooks/refresh_generations.sh.erb')
        write_file('bin/refresh_generations', content, force: options[:force], executable: true)
      end

      def create_git_hooks
        hooks = []

        # Only create git hooks if .git directory exists
        return hooks unless File.directory?(File.join(project_root, '.git'))

        %w[post-rewrite pre-merge-commit].each do |hook|
          content = render_template("git_hooks/#{hook}.sh.erb")
          hooks << write_file(".git/hooks/#{hook}", content, force: options[:force], executable: true)
        end

        hooks
      end

      def create_gitattributes
        content = render_template('git_hooks/gitattributes.erb')
        write_file('.gitattributes', content, force: options[:force])
      end
    end
  end
end
