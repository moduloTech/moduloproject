# frozen_string_literal: true

RSpec.describe Moduloproject::Generators do
  let(:project_root) { Dir.mktmpdir }
  let(:context) { Moduloproject::Context.new(project_root: project_root) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '::REGISTRY' do
    it 'contains all expected generators' do
      expect(described_class::REGISTRY.keys).to contain_exactly(
        :docker, :ci, :devcontainer, :hooks, :claude, :config
      )
    end

    it 'maps to correct generator classes' do
      expect(described_class::REGISTRY[:docker]).to eq(Moduloproject::Generators::Docker)
      expect(described_class::REGISTRY[:ci]).to eq(Moduloproject::Generators::GitlabCi)
      expect(described_class::REGISTRY[:devcontainer]).to eq(Moduloproject::Generators::Devcontainer)
      expect(described_class::REGISTRY[:hooks]).to eq(Moduloproject::Generators::GitHooks)
      expect(described_class::REGISTRY[:claude]).to eq(Moduloproject::Generators::ClaudeCode)
      expect(described_class::REGISTRY[:config]).to eq(Moduloproject::Generators::Config)
    end
  end

  describe '.run' do
    it 'runs a specific generator' do
      result = described_class.run(:docker, context, force: true)
      expect(result).to be_an(Array)
      expect(File.exist?(File.join(project_root, 'Dockerfile'))).to be true
    end

    it 'accepts string component names' do
      result = described_class.run('docker', context, force: true)
      expect(result).to be_an(Array)
    end

    it 'raises ArgumentError for unknown generator' do
      expect { described_class.run(:unknown, context) }.to raise_error(ArgumentError, /Unknown generator/)
    end
  end

  describe '.run_all' do
    before do
      FileUtils.mkdir_p(File.join(project_root, '.git/hooks'))
    end

    it 'runs all default generators' do
      results = described_class.run_all(context, force: true)

      expect(results.keys).to contain_exactly(:docker, :devcontainer, :config, :ci, :hooks, :claude)
      expect(results[:docker]).to be_an(Array)
    end

    it 'creates files from all generators' do
      described_class.run_all(context, force: true)

      expect(File.exist?(File.join(project_root, 'Dockerfile'))).to be true
      expect(File.exist?(File.join(project_root, '.devcontainer/Dockerfile'))).to be true
      expect(File.exist?(File.join(project_root, 'config/database.yml'))).to be true
      expect(File.exist?(File.join(project_root, '.gitlab-ci.yml'))).to be true
      expect(File.exist?(File.join(project_root, 'bin/dc'))).to be true
      expect(File.exist?(File.join(project_root, 'CLAUDE.md'))).to be true
    end

    it 'accepts custom generator list' do
      results = described_class.run_all(context, generators: %i[docker config], force: true)

      expect(results.keys).to contain_exactly(:docker, :config)
    end
  end

  describe '.available' do
    it 'returns list of generator names' do
      expect(described_class.available).to contain_exactly(
        :docker, :ci, :devcontainer, :hooks, :claude, :config
      )
    end
  end

  describe '.exists?' do
    it 'returns true for existing generators' do
      expect(described_class.exists?(:docker)).to be true
      expect(described_class.exists?('ci')).to be true
    end

    it 'returns false for non-existing generators' do
      expect(described_class.exists?(:unknown)).to be false
    end
  end
end
