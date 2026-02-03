# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module Moduloproject
  module Generators
    # Base class for all Moduloproject generators.
    # Provides common functionality for file operations and template rendering.
    class Base
      VERSION = 1

      attr_reader :context, :options

      # Initialize a new generator
      #
      # @param context [Context] The project context
      # @param options [Hash] Generator options
      def initialize(context, options = {})
        @context = context
        @options = options
      end

      # Run the generator - must be implemented by subclasses
      #
      # @return [Array<String>] List of generated file paths
      def generate
        raise NotImplementedError, "#{self.class} must implement #generate"
      end

      # Get the generator name (used for keepfile tracking)
      #
      # @return [String] Generator name
      def generator_name
        self.class.name.split('::').last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      # Get the generator version
      #
      # @return [Integer] Version number
      def version
        self.class.const_get(:VERSION)
      rescue NameError
        1
      end

      protected

      # Render a template file with the current context
      #
      # @param template_path [String] Path to template relative to templates directory
      # @return [String] Rendered template content
      def render_template(template_path)
        TemplateEngine.load(template_path, context)
      end

      # Write content to a file in the project
      #
      # @param relative_path [String] Path relative to project root
      # @param content [String] Content to write
      # @param options [Hash] Options (force: overwrite existing, executable: set execute permission)
      # @return [String] The absolute path to the written file
      def write_file(relative_path, content, options = {})
        absolute_path = File.join(project_root, relative_path)
        dir = File.dirname(absolute_path)

        FileUtils.mkdir_p(dir) unless File.directory?(dir)

        return absolute_path if File.exist?(absolute_path) && !options[:force]

        File.write(absolute_path, content)
        File.chmod(0o755, absolute_path) if options[:executable]

        log_action('create', relative_path)
        absolute_path
      end

      # Copy a static file to the project
      #
      # @param source_path [String] Path to source file relative to templates directory
      # @param destination_path [String] Path relative to project root
      # @param options [Hash] Options (force: overwrite existing, executable: set execute permission)
      # @return [String] The absolute path to the copied file
      def copy_file(source_path, destination_path, options = {})
        full_source = File.join(TemplateEngine.templates_root, TemplateEngine.default_version, source_path)
        content = File.read(full_source)
        write_file(destination_path, content, options)
      end

      # Check if a file exists in the project
      #
      # @param relative_path [String] Path relative to project root
      # @return [Boolean] True if file exists
      def file_exists?(relative_path)
        File.exist?(File.join(project_root, relative_path))
      end

      # Remove a file from the project
      #
      # @param relative_path [String] Path relative to project root
      # @return [void]
      def delete_file(relative_path)
        absolute_path = File.join(project_root, relative_path)
        return unless File.exist?(absolute_path)

        FileUtils.rm_f(absolute_path)
        log_action('remove', relative_path)
      end

      # Get the project root path
      #
      # @return [String] Absolute path to project root
      def project_root
        context.project_root
      end

      # Read the keepfile content
      #
      # @return [Hash] Keepfile data
      def read_keepfile
        keepfile_path = File.join(project_root, keepfile_name)
        return {} unless File.exist?(keepfile_path)

        YAML.load_file(keepfile_path) || {}
      end

      # Update the keepfile with the current generator version
      def update_keepfile
        config = read_keepfile
        config[generator_name] = { 'version' => version }
        write_file(keepfile_name, config.to_yaml, force: true)
      end

      # Check if the generator should run based on keepfile version
      #
      # @return [Boolean] True if generator should be skipped
      def skip_generation?
        return false if options[:force]

        config = read_keepfile
        stored_version = config.dig(generator_name, 'version').to_i
        stored_version >= version
      end

      private

      def keepfile_name
        '.moduloproject.yml'
      end

      def log_action(action, path)
        return unless options[:verbose]

        puts "  #{action.ljust(12)} #{path}"
      end
    end
  end
end
