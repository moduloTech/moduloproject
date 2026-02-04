# frozen_string_literal: true

module Moduloproject
  module Backends
    # Registry for Rails cache backend strategies.
    module RailsCache
      @strategies = {}

      def self.register(name, klass)
        @strategies[name.to_s] = klass
      end

      def self.for(name)
        @strategies.fetch(name.to_s) do
          raise ArgumentError, "Unknown Rails cache backend: #{name}. Available: #{@strategies.keys.join(', ')}"
        end
      end

      def self.available
        @strategies.keys
      end
    end
  end
end

require_relative 'rails_cache/redis'
require_relative 'rails_cache/solid_cache'
