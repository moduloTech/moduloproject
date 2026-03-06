# frozen_string_literal: true

module Moduloproject
  module Setup
    # Adds Brakeman gem to the project Gemfile for security analysis.
    class BrakemanSetup
      attr_reader :name, :options

      def initialize(name, options)
        @name = name
        @options = options
      end

      def execute
        puts 'Setting up Brakeman...'
        add_to_gemfile
        puts 'Brakeman configured successfully!'
      end

      private

      def add_to_gemfile
        gemfile_path = File.join(name, 'Gemfile')
        return unless File.exist?(gemfile_path)

        content = File.read(gemfile_path)
        return if content.include?('brakeman')

        File.open(gemfile_path, 'a') do |f|
          f.puts
          f.puts '# Security analysis'
          f.puts "gem 'brakeman', require: false, group: :development"
        end
      end
    end
  end
end
