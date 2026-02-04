# frozen_string_literal: true

module Moduloproject
  module Backends
    # Registry for Action Cable backend strategies.
    module ActionCable
      @strategies = {}

      def self.register(name, klass)
        @strategies[name.to_s] = klass
      end

      def self.for(name)
        @strategies.fetch(name.to_s) do
          raise ArgumentError, "Unknown Action Cable backend: #{name}. Available: #{@strategies.keys.join(', ')}"
        end
      end

      def self.available
        @strategies.keys
      end
    end
  end
end

require_relative 'action_cable/redis'
require_relative 'action_cable/solid_cable'
