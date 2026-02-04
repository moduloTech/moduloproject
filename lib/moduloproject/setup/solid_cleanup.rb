# frozen_string_literal: true

require 'fileutils'

module Moduloproject
  module Setup
    # Selectively cleans up unused Solid gems and files.
    # Only runs when some backends are Solid and some are not.
    class SolidCleanup
      attr_reader :name, :options, :recipe

      def initialize(name, options, recipe:)
        @name = name
        @options = options
        @recipe = recipe
      end

      def execute(resolved_backends:)
        return unless recipe.needs_solid_cleanup?(resolved_backends)

        puts 'Cleaning up unused Solid components...'
        remove_unused_solid_gems(resolved_backends)
        remove_solid_files
        puts 'Solid cleanup complete!'
      end

      private

      def remove_unused_solid_gems(resolved_backends)
        gemfile_path = File.join(name, 'Gemfile')
        return unless File.exist?(gemfile_path)

        content = File.read(gemfile_path)
        used_solid_gems = resolved_backends.values
                                           .select { |b| recipe.solid_backend_gems.key?(b.to_s) }
                                           .map { |b| recipe.solid_backend_gems[b.to_s] }

        recipe.solid_backend_gems.each_value do |gem_name|
          next if used_solid_gems.include?(gem_name)

          content = content.gsub(/^gem ['"]#{gem_name}['"].*\n/, '')
        end

        File.write(gemfile_path, content)
      end

      def remove_solid_files
        recipe.solid_files.each do |relative_path|
          file = File.join(name, relative_path)
          FileUtils.rm_f(file)
        end
      end
    end
  end
end
