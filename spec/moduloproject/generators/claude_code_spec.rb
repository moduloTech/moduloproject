# frozen_string_literal: true

require 'json'

RSpec.describe Moduloproject::Generators::ClaudeCode do
  let(:project_root) { Dir.mktmpdir }
  let(:context) do
    Moduloproject::Context.new(
      project_root: project_root,
      project_name: 'test-app',
      ruby_version: '3.3.0',
      rails_version: '8.1.0',
      adapter: 'postgresql',
      js_engine: :importmap,
      frontend: 'hotwire',
      test_command: 'bundle exec rspec',
      default_branch: 'main',
      active_job_backend: 'sidekiq'
    )
  end
  let(:ticketing) { nil }
  let(:generator) { described_class.new(context, force: true, ticketing: ticketing) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '#generate' do
    before { generator.generate }

    # --- Core files ---

    it 'creates .claude/settings.json with valid JSON' do
      path = File.join(project_root, '.claude/settings.json')
      expect(File.exist?(path)).to be true
      settings = JSON.parse(File.read(path))
      expect(settings).to have_key('permissions')
      expect(settings).to have_key('hooks')
      expect(settings).to have_key('env')
    end

    it 'creates CLAUDE.md' do
      path = File.join(project_root, 'CLAUDE.md')
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include('# test-app')
      expect(content).to include('3.3.0')
      expect(content).to include('8.1.0')
    end

    # --- Hooks ---

    it 'creates hook files' do
      %w[
        .claude/hooks/prevent-destructive.sh
        .claude/hooks/prevent-git-push.sh
        .claude/hooks/post-edit-rubocop.sh
        .claude/hooks/post-edit-brakeman.sh
      ].each do |hook|
        path = File.join(project_root, hook)
        expect(File.exist?(path)).to be(true), "Expected #{hook} to exist"
      end
    end

    it 'makes hooks executable' do
      path = File.join(project_root, '.claude/hooks/prevent-destructive.sh')
      expect(File.executable?(path)).to be true
    end

    # --- Rules ---

    it 'creates static rule files' do
      %w[
        .claude/rules/git-safety.md
        .claude/rules/prevent-destructive.md
      ].each do |rule|
        path = File.join(project_root, rule)
        expect(File.exist?(path)).to be(true), "Expected #{rule} to exist"
      end
    end

    it 'creates ruby-conventions rule from ERB' do
      path = File.join(project_root, '.claude/rules/ruby-conventions.md')
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include('3.3.0')
      expect(content).to include('8.1.0')
      expect(content).to include('PostgreSQL')
    end

    # --- Generic Skills ---

    it 'creates generic skill files' do
      %w[
        .claude/skills/commit/SKILL.md
        .claude/skills/migration/SKILL.md
        .claude/skills/rails-practices/SKILL.md
        .claude/skills/review-code/SKILL.md
        .claude/skills/review-performance/SKILL.md
        .claude/skills/review-security/SKILL.md
        .claude/skills/rspec-patterns/SKILL.md
      ].each do |skill|
        path = File.join(project_root, skill)
        expect(File.exist?(path)).to be(true), "Expected #{skill} to exist"
      end
    end

    # --- Agents ---

    it 'creates agent files' do
      %w[
        .claude/agents/code-review-specialist.md
        .claude/agents/debug-specialist.md
      ].each do |agent|
        path = File.join(project_root, agent)
        expect(File.exist?(path)).to be(true), "Expected #{agent} to exist"
      end
    end

    # --- Settings.json structure ---

    describe 'settings.json content' do
      let(:settings) { JSON.parse(File.read(File.join(project_root, '.claude/settings.json'))) }

      it 'has DISABLE_INSTALLATION_CHECKS env' do
        expect(settings.dig('env', 'DISABLE_INSTALLATION_CHECKS')).to eq('1')
      end

      it 'has allow permissions with standard tools' do
        allow_list = settings.dig('permissions', 'allow')
        expect(allow_list).to include('Bash(bundle exec rspec:*)')
        expect(allow_list).to include('Bash(bundle exec rubocop:*)')
        expect(allow_list).to include('Bash(bundle exec brakeman:*)')
        expect(allow_list).to include('Bash(git status:*)')
      end

      it 'denies git push' do
        deny_list = settings.dig('permissions', 'deny')
        expect(deny_list).to include('Bash(git push:*)')
      end

      it 'asks for git add and commit' do
        ask_list = settings.dig('permissions', 'ask')
        expect(ask_list).to include('Bash(git add:*)')
        expect(ask_list).to include('Bash(git commit:*)')
      end

      it 'has PreToolUse hooks' do
        pre_hooks = settings.dig('hooks', 'PreToolUse')
        expect(pre_hooks).to be_an(Array)
        expect(pre_hooks.first['matcher']).to eq('Bash')
      end

      it 'has PostToolUse hooks' do
        post_hooks = settings.dig('hooks', 'PostToolUse')
        expect(post_hooks).to be_an(Array)
        expect(post_hooks.first['matcher']).to eq('Edit|Write')
      end
    end

    # --- No ticketing ---

    it 'does not create .mcp.json without ticketing' do
      expect(File.exist?(File.join(project_root, '.mcp.json'))).to be false
    end

    it 'does not create MCP server without ticketing' do
      expect(File.exist?(File.join(project_root, '.claude/mcp-servers/ticket-ops/index.mjs'))).to be false
    end

    it 'does not create workflow skills without ticketing' do
      expect(File.exist?(File.join(project_root, '.claude/skills/brainstorm/SKILL.md'))).to be false
    end
  end

  # --- Hotwire frontend ---

  describe 'with hotwire frontend' do
    before { generator.generate }

    it 'creates stimulus conventions rule' do
      path = File.join(project_root, '.claude/rules/javascript-conventions-stimulus.md')
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include('Stimulus')
    end

    it 'does not create vue skills' do
      expect(File.exist?(File.join(project_root, '.claude/skills/vue-practices/SKILL.md'))).to be false
    end

    it 'does not create eslint hook' do
      expect(File.exist?(File.join(project_root, '.claude/hooks/post-edit-eslint.sh'))).to be false
    end

    it 'does not create vue rules' do
      expect(File.exist?(File.join(project_root, '.claude/rules/javascript-conventions-vue.md'))).to be false
    end

    it 'does not include npx eslint in settings allow list' do
      settings = JSON.parse(File.read(File.join(project_root, '.claude/settings.json')))
      expect(settings.dig('permissions', 'allow')).not_to include('Bash(npx eslint:*)')
    end
  end

  # --- Vue frontend ---

  describe 'with vue frontend' do
    let(:vue_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'vue-app',
        ruby_version: '3.3.0',
        rails_version: '8.1.0',
        adapter: 'postgresql',
        js_engine: :vite,
        frontend: 'vue'
      )
    end
    let(:generator) { described_class.new(vue_context, force: true) }

    before { generator.generate }

    it 'creates vue skills' do
      expect(File.exist?(File.join(project_root, '.claude/skills/vue-practices/SKILL.md'))).to be true
      expect(File.exist?(File.join(project_root, '.claude/skills/vitest-patterns/SKILL.md'))).to be true
    end

    it 'creates eslint hook' do
      expect(File.exist?(File.join(project_root, '.claude/hooks/post-edit-eslint.sh'))).to be true
    end

    it 'creates vue rules' do
      expect(File.exist?(File.join(project_root, '.claude/rules/javascript-conventions-vue.md'))).to be true
    end

    it 'includes npx eslint in settings allow list' do
      settings = JSON.parse(File.read(File.join(project_root, '.claude/settings.json')))
      expect(settings.dig('permissions', 'allow')).to include('Bash(npx eslint:*)')
      expect(settings.dig('permissions', 'allow')).to include('Bash(npx vitest:*)')
    end

    it 'includes eslint in post hooks' do
      settings = JSON.parse(File.read(File.join(project_root, '.claude/settings.json')))
      post_hooks = settings.dig('hooks', 'PostToolUse')
      hook_commands = post_hooks.first['hooks'].map { |h| h['command'] }
      expect(hook_commands).to include('.claude/hooks/post-edit-eslint.sh')
    end

    it 'does not create stimulus conventions' do
      expect(File.exist?(File.join(project_root, '.claude/rules/javascript-conventions-stimulus.md'))).to be false
    end
  end

  # --- MySQL ---

  describe 'with mysql database' do
    let(:mysql_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'mysql-app',
        adapter: 'mysql2'
      )
    end
    let(:generator) { described_class.new(mysql_context, force: true) }

    before { generator.generate }

    it 'shows MySQL in ruby-conventions rule' do
      content = File.read(File.join(project_root, '.claude/rules/ruby-conventions.md'))
      expect(content).to include('MySQL')
    end

    it 'shows MySQL in CLAUDE.md' do
      content = File.read(File.join(project_root, 'CLAUDE.md'))
      expect(content).to include('MySQL')
    end
  end

  # --- Ticketing: GitLab ---

  describe 'with gitlab ticketing' do
    let(:ticketing) do
      Moduloproject::TicketingConfig.new(
        provider: 'gitlab',
        gitlab_project: 'mygroup/myproject',
        gitlab_host: 'gitlab.example.com'
      )
    end

    before { generator.generate }

    it 'creates workflow skills' do
      %w[brainstorm implement review improve].each do |skill|
        path = File.join(project_root, ".claude/skills/#{skill}/SKILL.md")
        expect(File.exist?(path)).to be(true), "Expected #{skill} skill to exist"
      end
    end

    it 'creates MCP server files' do
      expect(File.exist?(File.join(project_root, '.claude/mcp-servers/ticket-ops/index.mjs'))).to be true
      expect(File.exist?(File.join(project_root, '.claude/mcp-servers/ticket-ops/package.json'))).to be true
    end

    it 'creates .mcp.json with gitlab config' do
      path = File.join(project_root, '.mcp.json')
      expect(File.exist?(path)).to be true
      mcp = JSON.parse(File.read(path))
      env = mcp.dig('mcpServers', 'ticket-ops', 'env')
      expect(env['TICKET_PROVIDER']).to eq('gitlab')
      expect(env['GITLAB_PROJECT']).to eq('mygroup/myproject')
      expect(env['GITLAB_HOST']).to eq('gitlab.example.com')
    end

    it 'creates docs directories with .gitkeep' do
      %w[docs/tickets docs/specs].each do |dir|
        expect(Dir.exist?(File.join(project_root, dir))).to be true
        expect(File.exist?(File.join(project_root, dir, '.gitkeep'))).to be true
      end
    end

    it 'includes glab in allow list' do
      settings = JSON.parse(File.read(File.join(project_root, '.claude/settings.json')))
      expect(settings.dig('permissions', 'allow')).to include('Bash(glab:*)')
    end
  end

  # --- Ticketing: Jira ---

  describe 'with jira ticketing' do
    let(:ticketing) do
      Moduloproject::TicketingConfig.new(
        provider: 'jira',
        jira_url: 'https://myorg.atlassian.net',
        jira_project: 'PROJ',
        jira_email: 'dev@example.com'
      )
    end

    before { generator.generate }

    it 'creates .mcp.json with jira config' do
      mcp = JSON.parse(File.read(File.join(project_root, '.mcp.json')))
      env = mcp.dig('mcpServers', 'ticket-ops', 'env')
      expect(env['TICKET_PROVIDER']).to eq('jira')
      expect(env['JIRA_URL']).to eq('https://myorg.atlassian.net')
      expect(env['JIRA_PROJECT']).to eq('PROJ')
      expect(env['JIRA_API_TOKEN']).to eq('${JIRA_API_TOKEN}')
    end

    it 'does not include glab in allow list' do
      settings = JSON.parse(File.read(File.join(project_root, '.claude/settings.json')))
      expect(settings.dig('permissions', 'allow')).not_to include('Bash(glab:*)')
    end
  end

  # --- Ticketing: Roadmap ---

  describe 'with roadmap ticketing' do
    let(:ticketing) do
      Moduloproject::TicketingConfig.new(
        provider: 'roadmap',
        roadmap_file: 'TODO.md'
      )
    end

    before { generator.generate }

    it 'creates .mcp.json with roadmap config' do
      mcp = JSON.parse(File.read(File.join(project_root, '.mcp.json')))
      env = mcp.dig('mcpServers', 'ticket-ops', 'env')
      expect(env['TICKET_PROVIDER']).to eq('roadmap')
      expect(env['ROADMAP_FILE']).to eq('TODO.md')
    end
  end

  # --- Keepfile / skip ---

  describe 'when skip_generation? returns true' do
    let(:generator_without_force) { described_class.new(context) }

    before do
      keepfile_path = File.join(project_root, '.moduloproject.yml')
      File.write(keepfile_path, { 'claude_code' => { 'version' => 2 } }.to_yaml)
    end

    it 'returns generated_files without creating files' do
      result = generator_without_force.generate
      expect(result).to eq(described_class::GENERATED_FILES)
      expect(File.exist?(File.join(project_root, '.claude/settings.json'))).to be false
    end
  end

  describe 'keepfile version' do
    it 'has VERSION 2' do
      expect(described_class::VERSION).to eq(2)
    end
  end
end
