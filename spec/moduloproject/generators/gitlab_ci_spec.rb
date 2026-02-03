# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::GitlabCi do
  let(:project_root) { Dir.mktmpdir }
  let(:context) do
    Moduloproject::Context.new(
      project_root: project_root,
      project_name: 'test-app',
      adapter: 'postgresql',
      js_engine: :importmap,
      production_url: 'app.example.com',
      staging_url: 'staging.example.com',
      review_base_url: 'review.example.com'
    )
  end
  let(:generator) { described_class.new(context, force: true) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '#generate' do
    before { generator.generate }

    it 'creates .gitlab-ci.yml' do
      ci_file = File.join(project_root, '.gitlab-ci.yml')
      expect(File.exist?(ci_file)).to be true

      content = File.read(ci_file)
      expect(content).to include('IMAGE_NAME: test-app')
      expect(content).to include('postgres:16-alpine')
      expect(content).to include('redis:7-alpine')
    end

    it 'creates executable bin/test' do
      test_script = File.join(project_root, 'bin/test')
      expect(File.exist?(test_script)).to be true
      expect(File.executable?(test_script)).to be true

      content = File.read(test_script)
      expect(content).to include('RAILS_ENV=test')
      expect(content).to include('bundle exec rspec')
    end

    it 'creates deploy configs when URLs are present' do
      expect(File.exist?(File.join(project_root, 'config/deploy/production.yaml'))).to be true
      expect(File.exist?(File.join(project_root, 'config/deploy/staging.yaml'))).to be true
      expect(File.exist?(File.join(project_root, 'config/deploy/review.yaml'))).to be true
    end

    it 'includes production URL in production config' do
      content = File.read(File.join(project_root, 'config/deploy/production.yaml'))
      expect(content).to include('app.example.com')
    end
  end

  describe 'without deployment URLs' do
    let(:no_urls_context) do
      Moduloproject::Context.new(
        project_root: project_root
      )
    end
    let(:no_urls_generator) { described_class.new(no_urls_context, force: true) }

    before { no_urls_generator.generate }

    it 'does not create deploy configs' do
      expect(File.exist?(File.join(project_root, 'config/deploy/production.yaml'))).to be false
      expect(File.exist?(File.join(project_root, 'config/deploy/staging.yaml'))).to be false
      expect(File.exist?(File.join(project_root, 'config/deploy/review.yaml'))).to be false
    end

    it 'excludes deploy sections from gitlab-ci' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).not_to include('deploy_production:')
      expect(content).not_to include('deploy_staging:')
      expect(content).not_to include('deploy_review:')
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

    it 'uses MySQL in CI config' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('mysql:8-alpine')
      expect(content).to include('MYSQL_DATABASE')
    end
  end
end
