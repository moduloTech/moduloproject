# frozen_string_literal: true

module Moduloproject
  module Generators
    # Claude Code generator creates Claude Code configuration files.
    # Migrated and enhanced from Modulorails::ClaudeCodeGenerator.
    class ClaudeCode < Base
      VERSION = 1

      GENERATED_FILES = %w[
        .claude/settings.json
        CLAUDE.md
      ].freeze

      # Generate Claude Code configuration files
      #
      # @return [Array<String>] List of generated file paths
      def generate
        return GENERATED_FILES if skip_generation?

        generated = []

        generated << create_settings
        generated << create_claude_md

        update_keepfile
        generated.compact
      end

      private

      def create_settings
        content = render_template('claude/settings.json.erb')
        write_file('.claude/settings.json', content, force: options[:force])
      end

      def create_claude_md
        content = render_template('claude/CLAUDE.md.erb')
        write_file('CLAUDE.md', content, force: options[:force])
      end
    end
  end
end
