# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::GitlabCi do
  let(:project_root) { Dir.mktmpdir }
  let(:context) do
    Moduloproject::Context.new(
      project_root: project_root,
      project_name: 'test-app',
      adapter: 'postgresql',
      js_engine: :importmap,
      frontend: 'vue',
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

    it 'includes seeds job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('seeds:')
      expect(content).to include('db:seed')
    end

    it 'includes rubocop job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('rubocop:')
      expect(content).to include('extends: .lint')
    end

    it 'includes rubocop_light job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('rubocop_light:')
      expect(content).to include('Metrics/PerceivedComplexity')
    end

    it 'includes bundleraudit job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('bundleraudit:')
      expect(content).to include('extends: .bundleraudit')
    end

    it 'includes brakeman job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('brakeman:')
      expect(content).to include('extends: .ruby_brakeman')
    end

    it 'creates config/ci.rb for Rails 8.1' do
      ci_runner = File.join(project_root, 'config/ci.rb')
      expect(File.exist?(ci_runner)).to be true

      content = File.read(ci_runner)
      expect(content).to include('CI.run do')
      expect(content).to include('step "Tests"')
      expect(content).to include('step "Seeds"')
      expect(content).to include('step "Security: Brakeman"')
    end
  end

  describe 'with vue frontend' do
    let(:vue_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'test-app',
        adapter: 'postgresql',
        frontend: 'vue'
      )
    end
    let(:vue_generator) { described_class.new(vue_context, force: true) }

    before { vue_generator.generate }

    it 'includes vitest job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('vitest:')
      expect(content).to include('npm run test')
    end

    it 'includes eslint job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('eslint:')
      expect(content).to include('npm run lint')
    end

    it 'includes vitest step in ci.rb' do
      content = File.read(File.join(project_root, 'config/ci.rb'))
      expect(content).to include('step "Vitest"')
      expect(content).to include('step "Style: JS"')
    end
  end

  describe 'with hotwire frontend' do
    let(:hotwire_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        project_name: 'test-app',
        adapter: 'postgresql',
        frontend: 'hotwire'
      )
    end
    let(:hotwire_generator) { described_class.new(hotwire_context, force: true) }

    before { hotwire_generator.generate }

    it 'excludes vitest job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).not_to include('vitest:')
    end

    it 'excludes eslint job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).not_to include('eslint:')
    end

    it 'excludes vitest step from ci.rb' do
      content = File.read(File.join(project_root, 'config/ci.rb'))
      expect(content).not_to include('step "Vitest"')
      expect(content).not_to include('step "Style: JS"')
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

    it 'uses MySQL in seeds job' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('mysql2://root@mysql/')
    end
  end

  describe 'with SQLite3 adapter' do
    let(:sqlite3_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        adapter: 'sqlite3'
      )
    end
    let(:sqlite3_generator) { described_class.new(sqlite3_context, force: true) }

    before { sqlite3_generator.generate }

    it 'does not include postgres or mysql services' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).not_to include('postgres:')
      expect(content).not_to include('mysql:')
    end

    it 'does not include DATABASE_TEST_URL' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).not_to include('DATABASE_TEST_URL')
    end

    it 'still includes redis service' do
      content = File.read(File.join(project_root, '.gitlab-ci.yml'))
      expect(content).to include('redis:7-alpine')
    end
  end

  describe 'CI runner for Rails < 8.1' do
    let(:rails80_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        rails_version: '8.0.0',
        frontend: 'vue'
      )
    end
    let(:rails80_generator) { described_class.new(rails80_context, force: true) }

    before { rails80_generator.generate }

    it 'creates bin/ci instead of config/ci.rb' do
      expect(File.exist?(File.join(project_root, 'bin/ci'))).to be true
      expect(File.exist?(File.join(project_root, 'config/ci.rb'))).to be false
    end

    it 'makes bin/ci executable' do
      expect(File.executable?(File.join(project_root, 'bin/ci'))).to be true
    end

    it 'includes CiRunner class in bin/ci' do
      content = File.read(File.join(project_root, 'bin/ci'))
      expect(content).to include('class CiRunner')
      expect(content).to include('ci.step "Tests"')
      expect(content).to include('ci.step "Seeds"')
      expect(content).to include('ci.run')
    end

    it 'includes vue steps in bin/ci for vue frontend' do
      content = File.read(File.join(project_root, 'bin/ci'))
      expect(content).to include('ci.step "Vitest"')
      expect(content).to include('ci.step "Style: JS"')
    end
  end

  describe 'CI runner for Rails < 8.1 with hotwire' do
    let(:rails72_hotwire_context) do
      Moduloproject::Context.new(
        project_root: project_root,
        rails_version: '7.2.0',
        frontend: 'hotwire'
      )
    end
    let(:rails72_generator) { described_class.new(rails72_hotwire_context, force: true) }

    before { rails72_generator.generate }

    it 'excludes vue steps from bin/ci' do
      content = File.read(File.join(project_root, 'bin/ci'))
      expect(content).not_to include('ci.step "Vitest"')
      expect(content).not_to include('ci.step "Style: JS"')
    end
  end

  describe 'when skip_generation? returns true' do
    let(:generator_without_force) { described_class.new(context) }

    before do
      keepfile_path = File.join(project_root, '.moduloproject.yml')
      File.write(keepfile_path, { 'gitlab_ci' => { 'version' => 3 } }.to_yaml)
    end

    it 'returns GENERATED_FILES without creating files' do
      result = generator_without_force.generate
      expect(result).to eq(described_class::GENERATED_FILES)
      expect(File.exist?(File.join(project_root, '.gitlab-ci.yml'))).to be false
    end
  end
end
