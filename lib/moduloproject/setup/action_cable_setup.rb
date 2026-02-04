# frozen_string_literal: true

module Moduloproject
  module Setup
    # Orchestrates Action Cable backend configuration.
    # Delegates to the appropriate backend strategy.
    class ActionCableSetup
      attr_reader :name, :options, :recipe

      def initialize(name, options, recipe:)
        @name = name
        @options = options
        @recipe = recipe
      end

      def execute
        backend_name = options.fetch(:action_cable) { recipe.backend_for(:action_cable) }
        strategy_class = Backends::ActionCable.for(backend_name)
        strategy = strategy_class.new(name, options)

        puts "Configuring Action Cable with #{backend_name}..."
        strategy.apply
        puts "Action Cable configured with #{backend_name}!"
      end
    end
  end
end
