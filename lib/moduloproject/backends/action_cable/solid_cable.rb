# frozen_string_literal: true

module Moduloproject
  module Backends
    module ActionCable
      # Solid Cable strategy for Action Cable.
      # Keeps the default solid_cable adapter (no-op).
      class SolidCable
        attr_reader :name, :options

        def initialize(name, options)
          @name = name
          @options = options
        end

        def apply
          # Solid Cable is the Rails 8 default - no changes needed
        end

        def gem_name
          'solid_cable'
        end

        def adapter_name
          :solid_cable
        end
      end

      register('solid_cable', SolidCable)
    end
  end
end
