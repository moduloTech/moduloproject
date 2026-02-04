# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::Config do
  let(:project_root) { Dir.mktmpdir }
  let(:context) do
    Moduloproject::Context.new(
      project_root: project_root,
      project_name: 'test-app',
      adapter: 'postgresql'
    )
  end
  let(:generator) { described_class.new(context, force: true) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '#generate' do
    before { generator.generate }

    it 'creates config/database.yml' do
      db_config = File.join(project_root, 'config/database.yml')
      expect(File.exist?(db_config)).to be true

      content = File.read(db_config)
      expect(content).to include('adapter: postgresql')
      expect(content).to include('postgresql://postgres:postgres@database/test-app')
      expect(content).to match(/^staging:\n\s+<<: \*default$/)
      expect(content).to match(/^production:\n\s+<<: \*default$/)
    end

    it 'creates config/cable.yml' do
      cable_config = File.join(project_root, 'config/cable.yml')
      expect(File.exist?(cable_config)).to be true

      content = File.read(cable_config)
      expect(content).to include('adapter: redis')
      expect(content).to include('redis://redis:6379')
    end

    it 'creates config/puma.rb' do
      puma_config = File.join(project_root, 'config/puma.rb')
      expect(File.exist?(puma_config)).to be true

      content = File.read(puma_config)
      expect(content).to include('RAILS_MAX_THREADS')
      expect(content).to include('WEB_CONCURRENCY')
      expect(content).to include('plugin :tmp_restart')
    end
  end

  describe 'with MySQL adapter' do
    let(:mysql_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'mysql-app',
        adapter: 'mysql2'
      )
    end
    let(:mysql_generator) { described_class.new(mysql_context, force: true) }

    before { mysql_generator.generate }

    it 'creates MySQL database config' do
      content = File.read(File.join(project_root, 'config/database.yml'))
      expect(content).to include('adapter: mysql2')
      expect(content).to include('mysql2://root@database/mysql-app')
    end
  end

  describe 'when uses_redis is false' do
    let(:no_redis_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'test-app',
        adapter: 'postgresql',
        uses_redis: false
      )
    end
    let(:no_redis_generator) { described_class.new(no_redis_context, force: true) }

    before { no_redis_generator.generate }

    it 'still creates other config files' do
      expect(File.exist?(File.join(project_root, 'config/database.yml'))).to be true
      expect(File.exist?(File.join(project_root, 'config/puma.rb'))).to be true
    end
  end

  describe 'with SQLite3 adapter' do
    let(:sqlite_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'sqlite-app',
        adapter: 'sqlite3'
      )
    end
    let(:sqlite_generator) { described_class.new(sqlite_context, force: true) }

    before { sqlite_generator.generate }

    it 'does not create config/database.yml' do
      expect(File.exist?(File.join(project_root, 'config/database.yml'))).to be false
    end

    it 'still creates other config files' do
      expect(File.exist?(File.join(project_root, 'config/cable.yml'))).to be true
      expect(File.exist?(File.join(project_root, 'config/puma.rb'))).to be true
    end
  end

  describe 'when skip_generation? returns true' do
    let(:generator_without_force) { described_class.new(context) }

    before do
      keepfile_path = File.join(project_root, '.moduloproject.yml')
      File.write(keepfile_path, { 'config' => { 'version' => 2 } }.to_yaml)
    end

    it 'returns GENERATED_FILES without creating files' do
      result = generator_without_force.generate
      expect(result).to eq(described_class::GENERATED_FILES)
      expect(File.exist?(File.join(project_root, 'config/database.yml'))).to be false
    end
  end
end
