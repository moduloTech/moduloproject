# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::Devcontainer do
  let(:project_root) { Dir.mktmpdir }
  let(:context) do
    Moduloproject::Context.new(
      project_root: project_root,
      project_name: 'test-app',
      ruby_version: '3.3.0',
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

    it 'creates devcontainer.json' do
      json_file = File.join(project_root, '.devcontainer/devcontainer.json')
      expect(File.exist?(json_file)).to be true

      content = File.read(json_file)
      expect(content).to include('"name": "test-app"')
      expect(content).to include('"workspaceFolder": "/rails"')
      expect(content).to include('database:5432')
    end

    it 'creates compose.yml' do
      compose_file = File.join(project_root, '.devcontainer/compose.yml')
      expect(File.exist?(compose_file)).to be true

      content = File.read(compose_file)
      expect(content).to include('modulotechgroup/test-app:dev')
      expect(content).to include('postgres:16-alpine')
      expect(content).to include('redis:7-alpine')
    end

    it 'creates Dockerfile' do
      dockerfile = File.join(project_root, '.devcontainer/Dockerfile')
      expect(File.exist?(dockerfile)).to be true

      content = File.read(dockerfile)
      expect(content).to include('FROM ruby:3.3.0-alpine')
      expect(content).to include('postgresql-dev')
    end
  end

  describe 'with MySQL adapter' do
    let(:mysql_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        adapter: 'mysql2'
      )
    end
    let(:mysql_generator) { described_class.new(mysql_context, force: true) }

    before { mysql_generator.generate }

    it 'uses MySQL in devcontainer.json' do
      content = File.read(File.join(project_root, '.devcontainer/devcontainer.json'))
      expect(content).to include('database:3306')
    end

    it 'uses MySQL in compose.yml' do
      content = File.read(File.join(project_root, '.devcontainer/compose.yml'))
      expect(content).to include('mysql/mysql-server:8.0')
    end

    it 'uses MySQL dev packages in Dockerfile' do
      content = File.read(File.join(project_root, '.devcontainer/Dockerfile'))
      expect(content).to include('mysql-dev')
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

    it 'includes Bun services in compose.yml' do
      content = File.read(File.join(project_root, '.devcontainer/compose.yml'))
      expect(content).to include('bun run build --watch')
      expect(content).to include('bun run watch:css')
    end

    it 'includes Bun installation in Dockerfile' do
      content = File.read(File.join(project_root, '.devcontainer/Dockerfile'))
      expect(content).to include('bun.sh/install')
    end
  end
end
