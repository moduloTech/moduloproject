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
  end
end
