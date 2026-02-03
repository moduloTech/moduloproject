# frozen_string_literal: true

require_relative 'generators/base'
require_relative 'generators/docker'
require_relative 'generators/gitlab_ci'
require_relative 'generators/devcontainer'
require_relative 'generators/git_hooks'
require_relative 'generators/claude_code'
require_relative 'generators/config'

module Moduloproject
  # Generators module provides a registry and runner for all project generators.
  module Generators
    # Registry of available generators
    REGISTRY = {
      docker: Docker,
      ci: GitlabCi,
      devcontainer: Devcontainer,
      hooks: GitHooks,
      claude: ClaudeCode,
      config: Config
    }.freeze

    # Default generators to run (in order)
    DEFAULT_GENERATORS = %i[docker devcontainer config ci hooks claude].freeze

    class << self
      # Run a specific generator
      #
      # @param component [Symbol] Generator component name from REGISTRY
      # @param context [Context] The project context
      # @param options [Hash] Generator options
      # @return [Array<String>] List of generated file paths
      def run(component, context, options = {})
        generator_class = REGISTRY[component.to_sym]
        raise ArgumentError, "Unknown generator: #{component}" unless generator_class

        generator = generator_class.new(context, options)
        generator.generate
      end

      # Run all default generators
      #
      # @param context [Context] The project context
      # @param options [Hash] Generator options
      # @return [Hash<Symbol, Array<String>>] Map of generator names to generated files
      def run_all(context, options = {})
        results = {}
        generators = options[:generators] || DEFAULT_GENERATORS

        generators.each do |component|
          results[component] = run(component, context, options)
        end

        results
      end

      # List available generator names
      #
      # @return [Array<Symbol>] List of generator names
      def available
        REGISTRY.keys
      end

      # Check if a generator exists
      #
      # @param component [Symbol] Generator name
      # @return [Boolean] True if generator exists
      def exists?(component)
        REGISTRY.key?(component.to_sym)
      end
    end
  end
end
