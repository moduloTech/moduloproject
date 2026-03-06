# frozen_string_literal: true

require 'tty-prompt'

module Moduloproject
  # TicketingConfig resolves and holds ticketing provider configuration.
  # Supports GitLab, Jira, Roadmap file, or none.
  # Resolution order: CLI options > interactive TTY prompt > none (non-interactive).
  class TicketingConfig
    PROVIDERS = %w[gitlab jira roadmap none].freeze

    attr_reader :provider, :gitlab_project, :gitlab_host,
                :jira_url, :jira_project, :jira_email, :roadmap_file

    # Resolve ticketing configuration from CLI options or interactive prompt.
    #
    # @param options [Hash] CLI options
    # @return [TicketingConfig]
    def self.resolve(options)
      if options[:ticket_provider]
        from_cli(options)
      elsif $stdin.tty?
        from_prompt
      else
        new(provider: 'none')
      end
    end

    # Build from CLI options
    #
    # @param options [Hash] CLI options
    # @return [TicketingConfig]
    def self.from_cli(options)
      new(
        provider: options[:ticket_provider],
        gitlab_project: options[:gitlab_project],
        gitlab_host: options[:gitlab_host] || 'gitlab.com',
        jira_url: options[:jira_url],
        jira_project: options[:jira_project],
        jira_email: options[:jira_email],
        roadmap_file: options[:roadmap_file] || 'ROADMAP.md'
      )
    end

    # Build from interactive TTY prompt
    #
    # @return [TicketingConfig]
    def self.from_prompt
      prompt = TTY::Prompt.new
      provider = prompt.select('Ticketing provider?', PROVIDERS)
      return new(provider: 'none') if provider == 'none'

      attrs = prompt_provider_details(prompt, provider)
      new(provider: provider, **attrs)
    end

    # @api private
    def self.prompt_provider_details(prompt, provider)
      case provider
      when 'gitlab' then prompt_gitlab(prompt)
      when 'jira'   then prompt_jira(prompt)
      when 'roadmap' then prompt_roadmap(prompt)
      else {}
      end
    end
    private_class_method :prompt_provider_details

    def self.prompt_gitlab(prompt)
      {
        gitlab_project: prompt.ask('GitLab project path (e.g. group/project):'),
        gitlab_host: prompt.ask('GitLab hostname:', default: 'gitlab.com')
      }
    end
    private_class_method :prompt_gitlab

    def self.prompt_jira(prompt)
      {
        jira_url: prompt.ask('Jira instance URL:'),
        jira_project: prompt.ask('Jira project key:'),
        jira_email: prompt.ask('Jira API email:')
      }
    end
    private_class_method :prompt_jira

    def self.prompt_roadmap(prompt)
      { roadmap_file: prompt.ask('Roadmap file path:', default: 'ROADMAP.md') }
    end
    private_class_method :prompt_roadmap

    # @param attrs [Hash] Configuration attributes
    # @option attrs [String] :provider Provider name (required)
    # @option attrs [String] :gitlab_project GitLab project path
    # @option attrs [String] :gitlab_host GitLab hostname
    # @option attrs [String] :jira_url Jira instance URL
    # @option attrs [String] :jira_project Jira project key
    # @option attrs [String] :jira_email Jira API email
    # @option attrs [String] :roadmap_file Roadmap file path
    def initialize(**attrs)
      validate_provider!(attrs[:provider])
      @provider = attrs[:provider]
      @gitlab_project = attrs[:gitlab_project]
      @gitlab_host = attrs[:gitlab_host]
      @jira_url = attrs[:jira_url]
      @jira_project = attrs[:jira_project]
      @jira_email = attrs[:jira_email]
      @roadmap_file = attrs[:roadmap_file]
    end

    def enabled?
      provider != 'none'
    end

    def gitlab?
      provider == 'gitlab'
    end

    def jira?
      provider == 'jira'
    end

    def roadmap?
      provider == 'roadmap'
    end

    private

    def validate_provider!(provider)
      return if PROVIDERS.include?(provider)

      raise ArgumentError,
            "Invalid ticketing provider: #{provider}. Valid options: #{PROVIDERS.join(', ')}"
    end
  end
end
