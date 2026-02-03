# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::Docker do
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

    it 'creates Dockerfile' do
      dockerfile = File.join(project_root, 'Dockerfile')
      expect(File.exist?(dockerfile)).to be true

      content = File.read(dockerfile)
      expect(content).to include('ARG RUBY_VERSION=3.3.0')
      expect(content).to include('FROM docker.io/library/ruby:$RUBY_VERSION-alpine')
      expect(content).to include('postgresql-client')
    end

    it 'creates .dockerignore' do
      dockerignore = File.join(project_root, '.dockerignore')
      expect(File.exist?(dockerignore)).to be true

      content = File.read(dockerignore)
      expect(content).to include('.DS_Store')
      expect(content).to include('.moduloproject.yml')
    end

    it 'creates executable docker-entrypoint' do
      entrypoint = File.join(project_root, 'bin/docker-entrypoint')
      expect(File.exist?(entrypoint)).to be true
      expect(File.executable?(entrypoint)).to be true

      content = File.read(entrypoint)
      expect(content).to include('#!/bin/sh')
      expect(content).to include('db:prepare')
    end

    it 'creates keepfile' do
      keepfile = File.join(project_root, '.moduloproject.yml')
      expect(File.exist?(keepfile)).to be true

      config = YAML.load_file(keepfile)
      expect(config.dig('docker', 'version')).to eq(2)
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

    it 'uses MySQL client in Dockerfile' do
      content = File.read(File.join(project_root, 'Dockerfile'))
      expect(content).to include('mysql-client')
      expect(content).not_to include('postgresql-client')
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

    it 'includes Bun installation in Dockerfile' do
      content = File.read(File.join(project_root, 'Dockerfile'))
      expect(content).to include('bun.sh/install')
      expect(content).to include('bun install --frozen-lockfile')
    end
  end

  describe '#version' do
    it 'returns 2' do
      expect(generator.version).to eq(2)
    end
  end

  describe '#generator_name' do
    it 'returns docker' do
      expect(generator.generator_name).to eq('docker')
    end
  end
end
