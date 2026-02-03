# frozen_string_literal: true

require 'erb'

module Moduloproject
  # TemplateEngine handles loading and rendering ERB templates.
  # This is a minimal stub that will be enhanced in Phase 3.
  class TemplateEngine
    class TemplateNotFoundError < StandardError; end

    class << self
      # Load and render a template with the given context
      #
      # @param template_path [String] Relative path to template from templates directory
      # @param context [Context] The context object with project data
      # @return [String] The rendered template content
      def load(template_path, context)
        full_path = resolve_template_path(template_path)
        raise TemplateNotFoundError, "Template not found: #{template_path}" unless File.exist?(full_path)

        template_content = File.read(full_path)
        render(template_content, context)
      end

      # Render ERB template content with the given context
      #
      # @param content [String] ERB template content
      # @param context [Context] The context object with project data
      # @return [String] The rendered content
      def render(content, context)
        binding_context = TemplateBinding.new(context)
        erb = ERB.new(content, trim_mode: '-')
        erb.result(binding_context.binding_for_erb)
      end

      # Get the templates root directory
      #
      # @return [String] Path to templates directory
      def templates_root
        File.expand_path('../../templates', __dir__)
      end

      # Get the default Rails version directory
      #
      # @return [String] Default version like 'rails-8.1'
      def default_version
        'rails-8.1'
      end

      private

      def resolve_template_path(template_path)
        # Try versioned path first
        versioned_path = File.join(templates_root, default_version, template_path)
        return versioned_path if File.exist?(versioned_path)

        # Fall back to direct path
        File.join(templates_root, template_path)
      end
    end

    # Internal class that provides the binding for ERB templates
    class TemplateBinding
      def initialize(context)
        @context = context
        expose_attribute_methods
        expose_helper_methods
        set_legacy_instance_variables
      end

      def binding_for_erb
        binding
      end

      private

      def expose_attribute_methods
        context = @context
        Context::ATTRIBUTE_KEYS.each do |key|
          define_singleton_method(key) { context.send(key) }
        end
      end

      def expose_helper_methods
        context = @context
        define_singleton_method(:mysql?) { context.mysql? }
        define_singleton_method(:postgresql?) { context.postgresql? }
        define_singleton_method(:webpacker?) { context.webpacker? }
        define_singleton_method(:bun?) { context.bun? }
        define_singleton_method(:importmap?) { context.importmap? }
        define_singleton_method(:rails_version_gte?) { |v| context.rails_version_gte?(v) }
      end

      def set_legacy_instance_variables
        # Legacy compatibility - templates use @data.field syntax
        @data = @context
        @adapter = @context.adapter
        @js_engine = @context.js_engine
        @image_name = @context.image_name
        @environment_name = @context.environment_name
        @review_base_url = @context.review_base_url
        @staging_url = @context.staging_url
        @production_url = @context.production_url
        @rails_72_and_more = @context.rails_version_gte?('7.2')
      end
    end
  end
end
