# frozen_string_literal: true

RSpec.shared_examples 'claude code files' do |combination|
  describe 'Claude Code files' do
    it 'creates .claude/settings.json with valid JSON' do
      path = File.join(project_root, '.claude/settings.json')
      expect(File.exist?(path)).to be true
      expect(path).to have_valid_json
    end

    it 'creates CLAUDE.md' do
      path = File.join(project_root, 'CLAUDE.md')
      expect(File.exist?(path)).to be true
      expect(File.read(path).strip).not_to be_empty
    end

    describe 'hooks' do
      %w[
        .claude/hooks/prevent-destructive.sh
        .claude/hooks/prevent-git-push.sh
        .claude/hooks/post-edit-rubocop.sh
        .claude/hooks/post-edit-brakeman.sh
      ].each do |hook|
        it "creates #{hook}" do
          path = File.join(project_root, hook)
          expect(File.exist?(path)).to be true
          expect(File.executable?(path)).to be true
        end
      end
    end

    describe 'rules' do
      %w[
        .claude/rules/git-safety.md
        .claude/rules/prevent-destructive.md
        .claude/rules/ruby-conventions.md
      ].each do |rule|
        it "creates #{rule}" do
          expect(File.exist?(File.join(project_root, rule))).to be true
        end
      end
    end

    describe 'generic skills' do
      %w[
        .claude/skills/commit/SKILL.md
        .claude/skills/migration/SKILL.md
        .claude/skills/rails-practices/SKILL.md
        .claude/skills/review-code/SKILL.md
        .claude/skills/review-performance/SKILL.md
        .claude/skills/review-security/SKILL.md
        .claude/skills/rspec-patterns/SKILL.md
      ].each do |skill|
        it "creates #{skill}" do
          expect(File.exist?(File.join(project_root, skill))).to be true
        end
      end
    end

    describe 'agents' do
      %w[
        .claude/agents/code-review-specialist.md
        .claude/agents/debug-specialist.md
      ].each do |agent|
        it "creates #{agent}" do
          expect(File.exist?(File.join(project_root, agent))).to be true
        end
      end
    end

    describe 'settings.json content' do
      let(:settings) { JSON.parse(File.read(File.join(project_root, '.claude/settings.json'))) }

      it 'has permissions with allow, deny, ask' do
        expect(settings['permissions']).to have_key('allow')
        expect(settings['permissions']).to have_key('deny')
        expect(settings['permissions']).to have_key('ask')
      end

      it 'denies git push' do
        expect(settings.dig('permissions', 'deny')).to include('Bash(git push:*)')
      end

      it 'has PreToolUse and PostToolUse hooks' do
        expect(settings['hooks']).to have_key('PreToolUse')
        expect(settings['hooks']).to have_key('PostToolUse')
      end

      it 'has env with DISABLE_INSTALLATION_CHECKS' do
        expect(settings.dig('env', 'DISABLE_INSTALLATION_CHECKS')).to eq('1')
      end
    end

    describe 'CLAUDE.md content' do
      let(:claude_md) { File.read(File.join(project_root, 'CLAUDE.md')) }

      it 'contains the project name as title' do
        expect(claude_md).to match(/^# #{Regexp.escape(combination.app_name)}/)
      end

      it 'mentions the Ruby version' do
        expect(claude_md).to include("Ruby Version**: #{combination.ruby}")
      end

      it 'mentions the Rails version' do
        expect(claude_md).to include("Rails Version**: #{combination.rails}")
      end

      it 'mentions the correct database' do
        case combination.database
        when 'mysql2'
          expect(claude_md).to include('MySQL')
        when 'postgresql', 'sqlite3'
          expect(claude_md).to include('PostgreSQL')
        end
      end

      it 'documents the development environment with Docker' do
        expect(claude_md).to include('.devcontainer/')
        expect(claude_md).to include('docker compose')
      end

      it 'documents testing commands' do
        expect(claude_md).to include('bin/test')
        expect(claude_md).to include('bundle exec rspec')
      end

      it 'documents database commands' do
        expect(claude_md).to include('rails db:migrate')
      end

      it 'documents key directories' do
        expect(claude_md).to include('app/')
        expect(claude_md).to include('config/')
        expect(claude_md).to include('db/')
        expect(claude_md).to include('spec/')
      end

      it 'documents git hooks' do
        expect(claude_md).to include('post-rewrite')
        expect(claude_md).to include('pre-merge-commit')
        expect(claude_md).to include('bin/refresh_generations')
      end
    end

    describe 'frontend-specific files' do
      if combination.respond_to?(:frontend) && combination.frontend == 'vue'
        it 'creates vue-specific skills' do
          expect(File.exist?(File.join(project_root, '.claude/skills/vue-practices/SKILL.md'))).to be true
          expect(File.exist?(File.join(project_root, '.claude/skills/vitest-patterns/SKILL.md'))).to be true
        end

        it 'creates eslint hook' do
          expect(File.exist?(File.join(project_root, '.claude/hooks/post-edit-eslint.sh'))).to be true
        end

        it 'creates vue conventions rule' do
          expect(File.exist?(File.join(project_root, '.claude/rules/javascript-conventions-vue.md'))).to be true
        end
      end

      if combination.respond_to?(:frontend) && combination.frontend == 'hotwire'
        it 'creates stimulus conventions rule' do
          expect(File.exist?(File.join(project_root, '.claude/rules/javascript-conventions-stimulus.md'))).to be true
        end
      end
    end
  end
end
