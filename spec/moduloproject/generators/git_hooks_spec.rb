# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::GitHooks do
  let(:project_root) { Dir.mktmpdir }
  let(:context) { Moduloproject::Context.new(project_root: project_root) }
  let(:generator) { described_class.new(context, force: true) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '#generate' do
    before do
      # Create .git directory to allow hook creation
      FileUtils.mkdir_p(File.join(project_root, '.git/hooks'))
      generator.generate
    end

    it 'creates executable bin/dc' do
      dc_script = File.join(project_root, 'bin/dc')
      expect(File.exist?(dc_script)).to be true
      expect(File.executable?(dc_script)).to be true

      content = File.read(dc_script)
      expect(content).to include('docker compose')
      expect(content).to include('.devcontainer/compose.yml')
    end

    it 'creates executable bin/dcr' do
      dcr_script = File.join(project_root, 'bin/dcr')
      expect(File.exist?(dcr_script)).to be true
      expect(File.executable?(dcr_script)).to be true

      content = File.read(dcr_script)
      expect(content).to include('GIT_AUTHOR_EMAIL')
      expect(content).to include('run --rm')
    end

    it 'creates executable bin/refresh_generations' do
      script = File.join(project_root, 'bin/refresh_generations')
      expect(File.exist?(script)).to be true
      expect(File.executable?(script)).to be true

      content = File.read(script)
      expect(content).to include('Gemfile.lock')
      expect(content).to include('bundle install')
    end

    it 'creates git hooks' do
      post_rewrite = File.join(project_root, '.git/hooks/post-rewrite')
      pre_merge = File.join(project_root, '.git/hooks/pre-merge-commit')

      expect(File.exist?(post_rewrite)).to be true
      expect(File.exist?(pre_merge)).to be true
      expect(File.executable?(post_rewrite)).to be true
      expect(File.executable?(pre_merge)).to be true
    end

    it 'creates .gitattributes' do
      gitattributes = File.join(project_root, '.gitattributes')
      expect(File.exist?(gitattributes)).to be true

      content = File.read(gitattributes)
      expect(content).to include('Gemfile.lock merge=ours')
      expect(content).to include('db/schema.rb merge=ours')
      expect(content).to include('diff=rails_credentials')
    end
  end

  describe 'without .git directory' do
    before do
      generator.generate
    end

    it 'still creates bin scripts' do
      expect(File.exist?(File.join(project_root, 'bin/dc'))).to be true
      expect(File.exist?(File.join(project_root, 'bin/dcr'))).to be true
      expect(File.exist?(File.join(project_root, 'bin/refresh_generations'))).to be true
    end

    it 'does not create git hooks' do
      expect(File.exist?(File.join(project_root, '.git/hooks/post-rewrite'))).to be false
      expect(File.exist?(File.join(project_root, '.git/hooks/pre-merge-commit'))).to be false
    end

    it 'still creates .gitattributes' do
      expect(File.exist?(File.join(project_root, '.gitattributes'))).to be true
    end
  end
end
