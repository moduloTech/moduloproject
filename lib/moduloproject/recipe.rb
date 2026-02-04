# frozen_string_literal: true

require 'yaml'

module Moduloproject
  # Loads and resolves version-specific recipes from YAML files.
  # Supports inheritance chains (e.g., rails-7.2 -> rails-8.0 -> rails-8.1).
  class Recipe
    class RecipeNotFoundError < StandardError; end
    class IncompatibleVersionError < StandardError; end
    class CircularInheritanceError < StandardError; end

    RECIPES_DIR = File.expand_path('../../recipes', __dir__)

    attr_reader :rails_version, :data

    def self.load(rails_version, recipes_dir: RECIPES_DIR)
      new(rails_version, recipes_dir: recipes_dir)
    end

    # Returns sorted list of available Rails versions from recipe files.
    def self.available_versions(recipes_dir: RECIPES_DIR)
      Dir.glob(File.join(recipes_dir, 'rails-*.yml'))
         .map { |f| File.basename(f, '.yml').delete_prefix('rails-') }
         .sort_by { |v| Gem::Version.new(v) }
    end

    # Returns the highest available Rails version.
    def self.latest_version(recipes_dir: RECIPES_DIR)
      available_versions(recipes_dir: recipes_dir).last
    end

    def initialize(rails_version, recipes_dir: RECIPES_DIR)
      @rails_version = rails_version
      @recipes_dir = recipes_dir
      @data = resolve_inheritance
    end

    # Returns the list of rails CLI options for the given frontend and database.
    # Dynamically adds --skip-solid when supports_skip_solid and all backends are non-solid.
    def rails_options(frontend:, database:, resolved_backends: {})
      opts = common_options(database)
      opts += frontend_options(frontend)
      opts += skip_solid_option(resolved_backends)
      opts
    end

    # Returns the default backend for a given concern (active_job, action_cable, rails_cache).
    def backend_for(concern)
      defaults = @data.fetch('backend_defaults', {})
      defaults[concern.to_s]
    end

    # Returns all available backends for a given concern.
    def available_backends_for(concern)
      available = @data.fetch('available_backends', {})
      available.fetch(concern.to_s, [])
    end

    # Validates that the given Ruby version is compatible with this Rails version.
    def validate_ruby!(version)
      compat = @data.fetch('compatibility', {})
      min = compat['ruby_minimum']
      max = compat['ruby_maximum']

      if min && Gem::Version.new(version) < Gem::Version.new(min)
        raise IncompatibleVersionError,
              "Ruby #{version} is below minimum #{min} for Rails #{@rails_version}"
      end

      if max && Gem::Version.new(version) > Gem::Version.new(max)
        raise IncompatibleVersionError,
              "Ruby #{version} exceeds maximum #{max} for Rails #{@rails_version}"
      end

      true
    end

    # Returns the default Ruby version for this Rails version.
    def default_ruby
      @data.dig('compatibility', 'ruby_default')
    end

    # Returns true if solid cleanup is needed: supports_skip_solid AND at least one
    # backend is solid (meaning others are non-solid and solid remnants must be cleaned).
    def needs_solid_cleanup?(resolved_backends)
      return false unless @data['supports_skip_solid']

      has_solid = resolved_backends.values.any? { |b| solid_backend?(b) }
      has_non_solid = resolved_backends.values.any? { |b| !solid_backend?(b) }
      has_solid && has_non_solid
    end

    # Returns the list of solid files to potentially clean up.
    def solid_files
      @data.fetch('solid_files', [])
    end

    # Returns the mapping of solid backend names to their gem names.
    def solid_backend_gems
      @data.fetch('solid_backend_gems', {})
    end

    # Returns whether this recipe supports --skip-solid.
    def supports_skip_solid?
      @data.fetch('supports_skip_solid', false)
    end

    private

    def resolve_inheritance
      chain = build_chain
      merged = {}
      chain.reverse.each do |version_data|
        merged = deep_merge(merged, version_data)
      end
      merged
    end

    def build_chain
      chain = []
      visited = Set.new
      current_version = "rails-#{@rails_version}"

      loop do
        raise CircularInheritanceError, "Circular inheritance: #{current_version}" if visited.include?(current_version)

        visited.add(current_version)
        yaml_data = load_yaml(current_version)
        chain << yaml_data

        parent = yaml_data.delete('inherits_from')
        break unless parent

        current_version = parent
      end

      chain
    end

    def load_yaml(version_key)
      path = File.join(@recipes_dir, "#{version_key}.yml")
      raise RecipeNotFoundError, "Recipe not found: #{version_key}" unless File.exist?(path)

      YAML.safe_load_file(path, permitted_classes: [Symbol]) || {}
    end

    def deep_merge(base, override)
      base.merge(override) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash) && !new_val.empty?
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end

    def common_options(database)
      raw = @data.dig('rails_options', 'common') || []
      raw.map { |opt| opt.gsub('<database>', rails_database_flag(database)) }
    end

    # Rails CLI expects 'mysql', not 'mysql2' (the gem name)
    def rails_database_flag(database)
      database == 'mysql2' ? 'mysql' : database
    end

    def frontend_options(frontend)
      @data.dig('rails_options', 'frontend', frontend) || []
    end

    def skip_solid_option(resolved_backends)
      return [] unless @data['supports_skip_solid']
      return [] if resolved_backends.empty?

      all_non_solid = resolved_backends.values.none? { |b| solid_backend?(b) }
      all_non_solid ? ['--skip-solid'] : []
    end

    def solid_backend?(backend_name)
      solid_backend_gems.key?(backend_name.to_s)
    end
  end
end
