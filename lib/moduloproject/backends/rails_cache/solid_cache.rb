# frozen_string_literal: true

module Moduloproject
  module Backends
    module RailsCache
      # Solid Cache strategy for Rails cache.
      # Keeps the default solid_cache_store (no-op).
      class SolidCache
        attr_reader :name, :options

        def initialize(name, options)
          @name = name
          @options = options
        end

        def apply
          # Solid Cache is the Rails 8 default - no changes needed
        end

        def gem_name
          'solid_cache'
        end

        def store_name
          :solid_cache_store
        end
      end

      register('solid_cache', SolidCache)
    end
  end
end
