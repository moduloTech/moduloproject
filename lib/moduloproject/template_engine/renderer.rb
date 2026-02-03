# frozen_string_literal: true

require 'erb'

module Moduloproject
  class TemplateEngine
    # Renderer handles ERB template rendering with context binding.
    class Renderer
      # Render ERB template content with the given context
      #
      # @param content [String] ERB template content
      # @param context [Context] The context object with project data
      # @param loader [Loader, nil] Optional loader for partial support
      # @return [String] The rendered content
      def render(content, context, loader: nil)
        binding_context = TemplateBinding.new(context, loader: loader)
        erb = ERB.new(content, trim_mode: '-')
        erb.result(binding_context.binding_for_erb)
      end
    end

    # TemplateBinding provides the binding for ERB templates.
    # It exposes context attributes, helper methods, and legacy instance variables.
    class TemplateBinding
      def initialize(context, loader: nil)
        @context = context
        @loader = loader
        expose_attribute_methods
        expose_helper_methods
        set_legacy_instance_variables
      end

      def binding_for_erb
        binding
      end

      # Render a partial from shared/partials/
      #
      # @param name [String] Partial name without leading underscore and extension
      # @return [String] Rendered partial content
      def partial(name)
        raise 'No loader configured for partials' unless @loader

        partial_content = @loader.load_partial(name)
        erb = ERB.new(partial_content, trim_mode: '-')
        erb.result(binding)
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
