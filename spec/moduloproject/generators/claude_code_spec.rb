# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::ClaudeCode do
  let(:project_root) { Dir.mktmpdir }
  let(:context) do
    Moduloproject::Context.new(
      project_root: project_root,
      project_name: 'test-app',
      ruby_version: '3.3.0',
      rails_version: '8.1.0',
      adapter: 'postgresql',
      js_engine: :importmap
    )
  end
  let(:generator) { described_class.new(context, force: true) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '#generate' do
    before { generator.generate }

    it 'creates .claude/settings.json' do
      settings_file = File.join(project_root, '.claude/settings.json')
      expect(File.exist?(settings_file)).to be true

      content = File.read(settings_file)
      expect(content).to include('"permissions"')
      expect(content).to include('bundle exec rspec')
      expect(content).to include('bundle exec rubocop')
    end

    it 'creates CLAUDE.md' do
      claude_md = File.join(project_root, 'CLAUDE.md')
      expect(File.exist?(claude_md)).to be true

      content = File.read(claude_md)
      expect(content).to include('# test-app')
      expect(content).to include('Ruby Version')
      expect(content).to include('3.3.0')
      expect(content).to include('8.1.0')
      expect(content).to include('PostgreSQL')
    end
  end

  describe 'with different database' do
    let(:mysql_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'mysql-app',
        adapter: 'mysql2'
      )
    end
    let(:mysql_generator) { described_class.new(mysql_context, force: true) }

    before { mysql_generator.generate }

    it 'shows MySQL in CLAUDE.md' do
      content = File.read(File.join(project_root, 'CLAUDE.md'))
      expect(content).to include('MySQL')
    end
  end

  describe 'with Bun JS engine' do
    let(:bun_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        js_engine: :bun
      )
    end
    let(:bun_generator) { described_class.new(bun_context, force: true) }

    before { bun_generator.generate }

    it 'shows Bun in CLAUDE.md' do
      content = File.read(File.join(project_root, 'CLAUDE.md'))
      expect(content).to include('Bun')
    end
  end

  describe 'when skip_generation? returns true' do
    let(:generator_without_force) { described_class.new(context) }

    before do
      keepfile_path = File.join(project_root, '.moduloproject.yml')
      File.write(keepfile_path, { 'claude_code' => { 'version' => 1 } }.to_yaml)
    end

    it 'returns GENERATED_FILES without creating files' do
      result = generator_without_force.generate
      expect(result).to eq(described_class::GENERATED_FILES)
      expect(File.exist?(File.join(project_root, '.claude/settings.json'))).to be false
    end
  end
end
