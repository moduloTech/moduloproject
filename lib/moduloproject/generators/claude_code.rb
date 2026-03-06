# frozen_string_literal: true

require 'json'

module Moduloproject
  module Generators
    # File maps for ClaudeCode generator: source template path => destination in project
    module ClaudeCodeFileMaps
      HOOKS = {
        'claude/hooks/prevent-destructive.sh' => '.claude/hooks/prevent-destructive.sh',
        'claude/hooks/prevent-git-push.sh' => '.claude/hooks/prevent-git-push.sh',
        'claude/hooks/post-edit-rubocop.sh' => '.claude/hooks/post-edit-rubocop.sh',
        'claude/hooks/post-edit-brakeman.sh' => '.claude/hooks/post-edit-brakeman.sh'
      }.freeze
      VUE_HOOKS = {
        'claude/hooks/post-edit-eslint.sh' => '.claude/hooks/post-edit-eslint.sh'
      }.freeze
      RULES = {
        'claude/rules/git-safety.md' => '.claude/rules/git-safety.md',
        'claude/rules/prevent-destructive.md' => '.claude/rules/prevent-destructive.md'
      }.freeze
      ERB_RULES = {
        'claude/rules/ruby-conventions.md.erb' => '.claude/rules/ruby-conventions.md'
      }.freeze
      VUE_RULES = {
        'claude/rules/javascript-conventions-vue.md' => '.claude/rules/javascript-conventions-vue.md'
      }.freeze
      HOTWIRE_ERB_RULES = {
        'claude/rules/javascript-conventions-stimulus.md.erb' => '.claude/rules/javascript-conventions-stimulus.md'
      }.freeze
      GENERIC_SKILLS = {
        'claude/skills/commit.md' => '.claude/skills/commit/SKILL.md',
        'claude/skills/migration.md' => '.claude/skills/migration/SKILL.md',
        'claude/skills/rails-practices.md' => '.claude/skills/rails-practices/SKILL.md',
        'claude/skills/review-code.md' => '.claude/skills/review-code/SKILL.md',
        'claude/skills/review-performance.md' => '.claude/skills/review-performance/SKILL.md',
        'claude/skills/review-security.md' => '.claude/skills/review-security/SKILL.md',
        'claude/skills/rspec-patterns.md' => '.claude/skills/rspec-patterns/SKILL.md'
      }.freeze
      VUE_SKILLS = {
        'claude/skills/vue-practices.md' => '.claude/skills/vue-practices/SKILL.md',
        'claude/skills/vitest-patterns.md' => '.claude/skills/vitest-patterns/SKILL.md'
      }.freeze
      WORKFLOW_SKILLS = {
        'claude/skills/brainstorm.md.erb' => '.claude/skills/brainstorm/SKILL.md',
        'claude/skills/implement.md.erb' => '.claude/skills/implement/SKILL.md',
        'claude/skills/review.md.erb' => '.claude/skills/review/SKILL.md',
        'claude/skills/improve.md.erb' => '.claude/skills/improve/SKILL.md'
      }.freeze
      AGENTS = {
        'claude/agents/code-review-specialist.md' => '.claude/agents/code-review-specialist.md',
        'claude/agents/debug-specialist.md' => '.claude/agents/debug-specialist.md'
      }.freeze
      MCP_SERVER_FILES = {
        'claude/mcp-servers/ticket-ops/index.mjs' => '.claude/mcp-servers/ticket-ops/index.mjs',
        'claude/mcp-servers/ticket-ops/package.json' => '.claude/mcp-servers/ticket-ops/package.json'
      }.freeze
    end

    # Claude Code generator creates a comprehensive Claude Code configuration.
    # Generates hooks, rules, skills, agents, settings.json, CLAUDE.md,
    # and optionally MCP server + workflow skills for ticketing integration.
    class ClaudeCode < Base
      VERSION = 2
      FM = ClaudeCodeFileMaps

      GENERATED_FILES = %w[
        .claude/settings.json
        CLAUDE.md
      ].freeze

      def generate
        return generated_files if skip_generation?

        generated = generate_core_files
        generated += generate_ticketing_files if ticketing_enabled?

        update_keepfile
        generated.compact
      end

      def generated_files
        GENERATED_FILES
      end

      private

      def generate_core_files
        create_hooks + create_rules + create_generic_skills +
          create_frontend_skills + create_agents +
          [create_settings, create_claude_md]
      end

      def generate_ticketing_files
        files = create_workflow_skills + create_mcp_server + [create_mcp_json]
        create_docs_directories
        files
      end

      def create_hooks
        files = copy_file_map(FM::HOOKS, executable: true)
        files += copy_file_map(FM::VUE_HOOKS, executable: true) if context.vue?
        files
      end

      def create_rules
        files = copy_file_map(FM::RULES) + render_file_map(FM::ERB_RULES)
        files += copy_file_map(FM::VUE_RULES) if context.vue?
        files += render_file_map(FM::HOTWIRE_ERB_RULES) if context.hotwire?
        files
      end

      def create_generic_skills = copy_file_map(FM::GENERIC_SKILLS)
      def create_frontend_skills = context.vue? ? copy_file_map(FM::VUE_SKILLS) : []
      def create_workflow_skills = render_file_map(FM::WORKFLOW_SKILLS)
      def create_agents = copy_file_map(FM::AGENTS)
      def create_mcp_server = copy_file_map(FM::MCP_SERVER_FILES)

      def create_settings
        content = "#{JSON.pretty_generate(build_settings_hash)}\n"
        write_file('.claude/settings.json', content, force: options[:force])
      end

      def create_claude_md
        write_file('CLAUDE.md', render_template('claude/CLAUDE.md.erb'), force: options[:force])
      end

      def create_mcp_json
        content = "#{JSON.pretty_generate(build_mcp_json_hash)}\n"
        write_file('.mcp.json', content, force: options[:force])
      end

      def create_docs_directories
        %w[docs/tickets docs/specs].each do |dir|
          full_path = File.join(project_root, dir)
          FileUtils.mkdir_p(full_path) unless File.directory?(full_path)
          gitkeep = File.join(full_path, '.gitkeep')
          File.write(gitkeep, '') unless File.exist?(gitkeep)
        end
      end

      def build_settings_hash
        {
          'env' => { 'DISABLE_INSTALLATION_CHECKS' => '1' },
          'permissions' => { 'allow' => build_allow_list, 'deny' => ['Bash(git push:*)'],
                             'ask' => ['Bash(git add:*)', 'Bash(git commit:*)'] },
          'hooks' => { 'PreToolUse' => build_pre_hooks, 'PostToolUse' => build_post_hooks }
        }
      end

      def build_allow_list
        list = base_allow_list
        list << 'Bash(npx eslint:*)' << 'Bash(npx vitest:*)' if context.vue?
        list << 'Bash(glab:*)' if ticketing_config&.gitlab?
        list
      end

      def base_allow_list
        [
          'Bash(bundle exec rspec:*)', 'Bash(bundle exec rubocop:*)',
          'Bash(bundle exec rails:*)', 'Bash(bundle exec brakeman:*)',
          'Bash(bin/test:*)', 'Bash(git status:*)', 'Bash(git log:*)',
          'Bash(git diff:*)', 'Bash(git branch:*)', 'Bash(git show:*)',
          'Bash(ls:*)', 'Bash(pwd:*)', 'Bash(which:*)', 'Bash(cat:*)',
          'Bash(head:*)', 'Bash(tail:*)', 'Bash(grep:*)', 'Bash(find:*)', 'Bash(wc:*)'
        ]
      end

      def build_pre_hooks
        [{
          'matcher' => 'Bash',
          'hooks' => [
            { 'type' => 'command', 'command' => '.claude/hooks/prevent-destructive.sh' },
            { 'type' => 'command', 'command' => '.claude/hooks/prevent-git-push.sh' }
          ]
        }]
      end

      def build_post_hooks
        hooks = [
          { 'type' => 'command', 'command' => '.claude/hooks/post-edit-rubocop.sh' },
          { 'type' => 'command', 'command' => '.claude/hooks/post-edit-brakeman.sh' }
        ]
        hooks << { 'type' => 'command', 'command' => '.claude/hooks/post-edit-eslint.sh' } if context.vue?
        [{ 'matcher' => 'Edit|Write', 'hooks' => hooks }]
      end

      def build_mcp_json_hash
        config = ticketing_config
        return {} unless config&.enabled?

        { 'mcpServers' => { 'ticket-ops' => build_mcp_server_config(config) } }
      end

      def build_mcp_server_config(config)
        { 'command' => 'node', 'args' => ['.claude/mcp-servers/ticket-ops/index.mjs'],
          'env' => { 'TICKET_PROVIDER' => config.provider }.merge(mcp_provider_env(config)) }
      end

      def mcp_provider_env(config)
        case config.provider
        when 'gitlab'  then mcp_gitlab_env(config)
        when 'jira'    then mcp_jira_env(config)
        when 'roadmap' then { 'ROADMAP_FILE' => config.roadmap_file || 'ROADMAP.md' }
        else {}
        end
      end

      def mcp_gitlab_env(config)
        { 'GITLAB_PROJECT' => config.gitlab_project || '', 'GITLAB_HOST' => config.gitlab_host || 'gitlab.com' }
      end

      def mcp_jira_env(config)
        { 'JIRA_URL' => config.jira_url || '', 'JIRA_PROJECT' => config.jira_project || '',
          'JIRA_EMAIL' => config.jira_email || '', 'JIRA_API_TOKEN' => '${JIRA_API_TOKEN}' }
      end

      def ticketing_enabled? = ticketing_config&.enabled? || false
      def ticketing_config = options[:ticketing]

      def copy_file_map(map, executable: false)
        map.map { |src, dest| copy_file(src, dest, force: options[:force], executable: executable) }
      end

      def render_file_map(map)
        map.map { |src, dest| write_file(dest, render_template(src), force: options[:force]) }
      end
    end
  end
end
