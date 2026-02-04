# frozen_string_literal: true

require_relative 'template_engine/manifest'
require_relative 'template_engine/inheritance_chain'
require_relative 'template_engine/loader'
require_relative 'template_engine/renderer'

module Moduloproject
  # TemplateEngine is a facade for template loading and rendering.
  # It provides a unified API while delegating to specialized components:
  # - Loader: resolves template paths through inheritance chain
  # - Renderer: handles ERB rendering with context binding
  # - Manifest: parses version manifest.yml files
  # - InheritanceChain: builds version inheritance chains
  class TemplateEngine
    class TemplateNotFoundError < StandardError; end

    class << self
      # Load and render a template with the given context
      #
      # @param template_path [String] Relative path to template from templates directory
      # @param context [Context] The context object with project data
      # @return [String] The rendered template content
      def load(template_path, context)
        rails_version = context.rails_version
        content = loader.load(template_path, rails_version)
        render(content, context)
      rescue Loader::TemplateNotFoundError => e
        raise TemplateNotFoundError, e.message
      end

      # Render ERB template content with the given context
      #
      # @param content [String] ERB template content
      # @param context [Context] The context object with project data
      # @return [String] The rendered content
      def render(content, context)
        renderer.render(content, context, loader: loader_for_context(context))
      end

      # Get the templates root directory
      #
      # @return [String] Path to templates directory
      def templates_root
        @templates_root ||= File.expand_path('../../templates', __dir__)
      end

      # Get the default Rails version directory
      #
      # @return [String] Default version like 'rails-8.1'
      def default_version
        loader.default_version
      end

      # Resolve the full path to a static file for copy_file
      #
      # @param source_path [String] Relative path to static file
      # @param rails_version [String] Rails version (e.g., '8.1.0' or 'rails-8.1')
      # @return [String] Full path to file
      # @raise [TemplateNotFoundError] If file not found in chain or shared
      def resolve_static_path(source_path, rails_version)
        full_path = loader.resolve_static_path(source_path, rails_version)
        raise TemplateNotFoundError, "Static file not found: #{source_path}" unless full_path

        full_path
      end

      # Get the inheritance chain for a version
      #
      # @param rails_version [String] Rails version
      # @return [InheritanceChain] The inheritance chain
      def inheritance_chain_for(rails_version)
        loader.inheritance_chain_for(rails_version)
      end

      # Normalize a version string to a directory name
      #
      # @param version [String] Version string or directory name
      # @return [String] Normalized directory name
      def normalize_version(version)
        loader.normalize_version(version)
      end

      # Reset cached instances (useful for testing)
      def reset!
        @loader = nil
        @renderer = nil
        @templates_root = nil
      end

      private

      def loader
        @loader ||= Loader.new(templates_root)
      end

      def renderer
        @renderer ||= Renderer.new
      end

      def loader_for_context(_context)
        # Create a loader scoped to the context's version for partials
        Loader.new(templates_root)
      end
    end
  end
end
