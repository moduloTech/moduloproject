# frozen_string_literal: true

require_relative 'manifest'

module Moduloproject
  class TemplateEngine
    # InheritanceChain builds the version inheritance chain.
    # For example: rails-7.2 -> rails-8.0 -> rails-8.1 (reference)
    class InheritanceChain
      class CircularInheritanceError < StandardError; end

      attr_reader :chain, :templates_root

      # @param starting_version [String] The starting version (e.g., 'rails-7.2')
      # @param templates_root [String] Path to templates directory
      def initialize(starting_version, templates_root)
        @starting_version = starting_version
        @templates_root = templates_root
        @manifests = {}
        @chain = build_chain
      end

      # Get all versions in the chain, from most specific to most general
      #
      # @return [Array<String>] List of version directory names
      def versions
        @chain.dup
      end

      # Get the merged variables from all manifests in the chain.
      # Child variables override parent variables.
      #
      # @return [Hash] Merged variables
      def merged_variables
        # Start from the end (reference) and merge toward the beginning (child)
        @chain.reverse.each_with_object({}) do |version, vars|
          manifest = manifest_for(version)
          vars.merge!(manifest.variables) if manifest
        end
      end

      # Get the manifest for a specific version
      #
      # @param version [String] Version directory name
      # @return [Manifest, nil] The manifest or nil if not found
      def manifest_for(version)
        @manifests[version] ||= Manifest.new(version, @templates_root)
        @manifests[version].exists? ? @manifests[version] : nil
      end

      # Check if a version is in the chain
      #
      # @param version [String] Version to check
      # @return [Boolean] True if version is in chain
      def include?(version)
        @chain.include?(version)
      end

      private

      def build_chain
        chain = []
        visited = Set.new
        current = @starting_version

        while current
          raise CircularInheritanceError, "Circular inheritance detected: #{current}" if visited.include?(current)

          visited.add(current)
          chain << current

          manifest = Manifest.new(current, @templates_root)
          current = manifest.inherits_from
        end

        chain
      end
    end
  end
end
