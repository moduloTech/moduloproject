# frozen_string_literal: true

module Moduloproject
  # Context encapsulates all project data needed by generators.
  # It replaces the Modulorails.data dependency with a pure Ruby class.
  class Context
    ATTRIBUTE_KEYS = %i[
      project_root
      project_name
      ruby_version
      rails_version
      bundler_version
      adapter
      js_engine
      frontend
      image_name
      environment_name
      production_url
      staging_url
      review_base_url
      uses_redis
    ].freeze

    attr_reader(*ATTRIBUTE_KEYS)

    def initialize(attributes = {})
      initialize_paths(attributes)
      initialize_versions(attributes)
      initialize_project_settings(attributes)
      initialize_urls(attributes)
    end

    def to_h
      ATTRIBUTE_KEYS.to_h { |key| [key, send(key)] }
    end

    def mysql?
      adapter.to_s.match?(/mysql/i)
    end

    def postgresql?
      adapter.to_s.match?(/postgres/i)
    end

    def sqlite3?
      adapter.to_s.match?(/sqlite/i)
    end

    def webpacker?
      js_engine == :webpacker
    end

    def bun?
      js_engine == :bun
    end

    def importmap?
      js_engine == :importmap
    end

    def vue?
      frontend.to_s == 'vue'
    end

    def hotwire?
      frontend.to_s == 'hotwire'
    end

    def rails_version_gte?(version)
      Gem::Version.new(rails_version) >= Gem::Version.new(version)
    end

    private

    def initialize_paths(attributes)
      @project_root = attributes[:project_root] || Dir.pwd
      @project_name = attributes[:project_name] || File.basename(@project_root)
    end

    def initialize_versions(attributes)
      @ruby_version = attributes[:ruby_version] || RUBY_VERSION
      @rails_version = attributes[:rails_version] || '8.1.0'
      @bundler_version = attributes[:bundler_version] || Gem::VERSION
    end

    def initialize_project_settings(attributes)
      @adapter = attributes[:adapter] || 'postgresql'
      @js_engine = attributes[:js_engine] || :importmap
      @frontend = attributes[:frontend]
      @image_name = attributes[:image_name] || parameterize(@project_name)
      @environment_name = attributes[:environment_name] || build_environment_name(@project_name)
      @uses_redis = attributes.fetch(:uses_redis, true)
    end

    def initialize_urls(attributes)
      @production_url = attributes[:production_url]
      @staging_url = attributes[:staging_url]
      @review_base_url = attributes[:review_base_url]
    end

    def parameterize(string)
      string.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
    end

    def build_environment_name(name)
      name.to_s
          .gsub(/[^a-zA-Z0-9]+/, '_')
          .gsub(/^(\d)/, 'MT_\1')
          .upcase
    end
  end
end
