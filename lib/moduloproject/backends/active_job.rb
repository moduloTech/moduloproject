# frozen_string_literal: true

module Moduloproject
  module Backends
    # Registry for Active Job backend strategies.
    module ActiveJob
      @strategies = {}

      def self.register(name, klass)
        @strategies[name.to_s] = klass
      end

      def self.for(name)
        @strategies.fetch(name.to_s) do
          raise ArgumentError, "Unknown Active Job backend: #{name}. Available: #{@strategies.keys.join(', ')}"
        end
      end

      def self.available
        @strategies.keys
      end
    end
  end
end

require_relative 'active_job/sidekiq'
require_relative 'active_job/solid_queue'
