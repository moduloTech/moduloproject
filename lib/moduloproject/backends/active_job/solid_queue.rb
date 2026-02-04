# frozen_string_literal: true

module Moduloproject
  module Backends
    module ActiveJob
      # Solid Queue strategy for Active Job.
      # Keeps the default solid_queue adapter (no-op for adapter config).
      class SolidQueue
        attr_reader :name, :options

        def initialize(name, options)
          @name = name
          @options = options
        end

        def apply
          # Solid Queue is the Rails 8 default - no changes needed
        end

        def gem_name
          'solid_queue'
        end

        def adapter_name
          :solid_queue
        end
      end

      register('solid_queue', SolidQueue)
    end
  end
end
