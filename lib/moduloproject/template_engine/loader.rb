# frozen_string_literal: true

require_relative 'inheritance_chain'

module Moduloproject
  class TemplateEngine
    # Loader resolves template paths through the inheritance chain.
    # Templates are searched in version directories from most specific to most general,
    # with fallback to shared/ directory.
    class Loader
      class TemplateNotFoundError < StandardError; end

      attr_reader :templates_root

      # @param templates_root [String] Path to templates directory
      def initialize(templates_root)
        @templates_root = templates_root
        @chain_cache = {}
      end

      # Load a template file, resolving through inheritance chain
      #
      # @param template_path [String] Relative path to template
      # @param rails_version [String] Rails version (e.g., '8.1.0' or 'rails-8.1')
      # @return [String] Template content
      # @raise [TemplateNotFoundError] If template not found in chain or shared
      def load(template_path, rails_version)
        full_path = resolve_path(template_path, rails_version)
        raise TemplateNotFoundError, "Template not found: #{template_path}" unless full_path

        File.read(full_path)
      end

      # Load a partial from shared/partials/
      #
      # @param name [String] Partial name without leading underscore and extension
      # @return [String] Partial content
      # @raise [TemplateNotFoundError] If partial not found
      def load_partial(name)
        partial_path = File.join(@templates_root, 'shared', 'partials', "_#{name}.erb")
        raise TemplateNotFoundError, "Partial not found: #{name}" unless File.exist?(partial_path)

        File.read(partial_path)
      end

      # Resolve the full path to a template through inheritance chain
      #
      # @param template_path [String] Relative path to template
      # @param rails_version [String] Rails version
      # @return [String, nil] Full path to template or nil if not found
      def resolve_path(template_path, rails_version)
        version_dir = normalize_version(rails_version)
        chain = inheritance_chain_for(version_dir)

        # Search through inheritance chain
        chain.versions.each do |version|
          full_path = File.join(@templates_root, version, template_path)
          return full_path if File.exist?(full_path)
        end

        # Fall back to shared directory
        shared_path = File.join(@templates_root, 'shared', template_path)
        return shared_path if File.exist?(shared_path)

        nil
      end

      # Resolve the full path to a static file for copy_file
      #
      # @param source_path [String] Relative path to static file
      # @param rails_version [String] Rails version
      # @return [String, nil] Full path to file or nil if not found
      def resolve_static_path(source_path, rails_version)
        resolve_path(source_path, rails_version)
      end

      # Get the inheritance chain for a version
      #
      # @param rails_version [String] Rails version
      # @return [InheritanceChain] The inheritance chain
      def inheritance_chain_for(rails_version)
        version_dir = normalize_version(rails_version)
        @chain_cache[version_dir] ||= InheritanceChain.new(version_dir, @templates_root)
      end

      # Normalize a version string to a directory name
      # "8.1.0" -> "rails-8.1", "rails-8.1" -> "rails-8.1"
      #
      # @param version [String] Version string or directory name
      # @return [String] Normalized directory name
      def normalize_version(version)
        version_str = version.to_s
        return version_str if version_str.start_with?('rails-')

        # Extract major.minor from version like "8.1.0"
        match = version_str.match(/^(\d+\.\d+)/)
        return 'rails-8.1' unless match

        "rails-#{match[1]}"
      end

      # Get the default version directory
      #
      # @return [String] Default version like 'rails-8.1'
      def default_version
        'rails-8.1'
      end
    end
  end
end
