# frozen_string_literal: true

require 'yaml'

module Moduloproject
  class TemplateEngine
    # Manifest parses and provides access to version manifest.yml files.
    # Each Rails version can have a manifest specifying inheritance and overrides.
    class Manifest
      class ParseError < StandardError; end

      attr_reader :version, :inherits_from, :variables, :overrides

      # @param version [String] The Rails version directory name (e.g., 'rails-8.1')
      # @param templates_root [String] Path to templates directory
      def initialize(version, templates_root)
        @version = version
        @templates_root = templates_root
        @inherits_from = nil
        @variables = {}
        @overrides = []
        load_manifest
      end

      # Check if this manifest explicitly overrides a template
      #
      # @param template_path [String] Relative path to template
      # @return [Boolean] True if template is listed in overrides
      def override?(template_path)
        @overrides.include?(template_path)
      end

      # Check if manifest file exists for this version
      #
      # @return [Boolean] True if manifest.yml exists
      def exists?
        File.exist?(manifest_path)
      end

      # Check if this is the reference version (no inheritance)
      #
      # @return [Boolean] True if this version has no parent
      def reference?
        @inherits_from.nil?
      end

      private

      def manifest_path
        File.join(@templates_root, @version, 'manifest.yml')
      end

      def load_manifest
        return unless exists?

        content = YAML.safe_load_file(manifest_path, permitted_classes: [Symbol])
        validate_manifest(content)
        parse_manifest(content)
      rescue Psych::SyntaxError => e
        raise ParseError, "Invalid YAML in #{manifest_path}: #{e.message}"
      end

      def validate_manifest(content)
        return if content.nil? || content.is_a?(Hash)

        raise ParseError, "Manifest must be a hash, got #{content.class}"
      end

      def parse_manifest(content)
        return if content.nil?

        @inherits_from = content['inherits_from']
        @variables = content['variables'] || {}
        @overrides = Array(content['overrides'])
      end
    end
  end
end
