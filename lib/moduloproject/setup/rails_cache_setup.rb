# frozen_string_literal: true

module Moduloproject
  module Setup
    # Orchestrates Rails cache backend configuration.
    # Delegates to the appropriate backend strategy.
    class RailsCacheSetup
      attr_reader :name, :options, :recipe

      def initialize(name, options, recipe:)
        @name = name
        @options = options
        @recipe = recipe
      end

      def execute
        backend_name = options.fetch(:rails_cache) { recipe.backend_for(:rails_cache) }
        strategy_class = Backends::RailsCache.for(backend_name)
        strategy = strategy_class.new(name, options)

        puts "Configuring Rails cache with #{backend_name}..."
        strategy.apply
        puts "Rails cache configured with #{backend_name}!"
      end
    end
  end
end
