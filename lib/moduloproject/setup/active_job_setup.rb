# frozen_string_literal: true

module Moduloproject
  module Setup
    # Orchestrates Active Job backend configuration.
    # Delegates to the appropriate backend strategy.
    class ActiveJobSetup
      attr_reader :name, :options, :recipe

      def initialize(name, options, recipe:)
        @name = name
        @options = options
        @recipe = recipe
      end

      def execute
        backend_name = options.fetch(:active_job) { recipe.backend_for(:active_job) }
        strategy_class = Backends::ActiveJob.for(backend_name)
        strategy = strategy_class.new(name, options)

        puts "Configuring Active Job with #{backend_name}..."
        strategy.apply
        puts "Active Job configured with #{backend_name}!"
      end
    end
  end
end
