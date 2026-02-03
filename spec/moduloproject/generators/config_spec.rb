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

    it 'creates config/initializers/0_redis.rb' do
      redis_init = File.join(project_root, 'config/initializers/0_redis.rb')
      expect(File.exist?(redis_init)).to be true

      content = File.read(redis_init)
      expect(content).to include('REDIS_URL')
      expect(content).to include('Redis.new')
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
end
