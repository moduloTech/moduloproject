# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/recipe'
require 'moduloproject/setup/solid_cleanup'

RSpec.describe Moduloproject::Setup::SolidCleanup do
  let(:name) { 'test-app' }
  let(:options) { {} }
  let(:recipe) { Moduloproject::Recipe.load('8.1') }
  let(:setup) { described_class.new(name, options, recipe: recipe) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmpdir, name) }

  before do
    FileUtils.mkdir_p(File.join(project_dir, 'config'))
    FileUtils.mkdir_p(File.join(project_dir, 'db'))
    Dir.chdir(tmpdir)
    allow(setup).to receive(:puts)
  end

  after do
    Dir.chdir('/')
    FileUtils.rm_rf(tmpdir)
  end

  describe '#execute' do
    context 'when cleanup is needed (mixed solid and non-solid backends)' do
      let(:resolved_backends) { { active_job: 'solid_queue', action_cable: 'redis', rails_cache: 'redis' } }

      before do
        File.write(File.join(project_dir, 'Gemfile'), <<~GEMFILE)
          gem 'rails'
          gem 'solid_cache'
          gem 'solid_queue'
          gem 'solid_cable'
        GEMFILE

        # Create solid files
        File.write(File.join(project_dir, 'config', 'cache.yml'), 'cache config')
        File.write(File.join(project_dir, 'config', 'queue.yml'), 'queue config')
        File.write(File.join(project_dir, 'config', 'recurring.yml'), 'recurring config')
        File.write(File.join(project_dir, 'db', 'cache_schema.rb'), 'cache schema')
        File.write(File.join(project_dir, 'db', 'queue_schema.rb'), 'queue schema')
        File.write(File.join(project_dir, 'db', 'cable_schema.rb'), 'cable schema')
      end

      it 'removes unused solid gems from Gemfile' do
        setup.execute(resolved_backends: resolved_backends)
        content = File.read(File.join(project_dir, 'Gemfile'))
        # solid_queue is used, so it should stay
        expect(content).to include("gem 'solid_queue'")
        # solid_cache and solid_cable are NOT used, so they should be removed
        expect(content).not_to include("gem 'solid_cache'")
        expect(content).not_to include("gem 'solid_cable'")
      end

      it 'removes solid config files' do
        setup.execute(resolved_backends: resolved_backends)
        expect(File.exist?(File.join(project_dir, 'config', 'cache.yml'))).to be false
        expect(File.exist?(File.join(project_dir, 'config', 'queue.yml'))).to be false
        expect(File.exist?(File.join(project_dir, 'config', 'recurring.yml'))).to be false
        expect(File.exist?(File.join(project_dir, 'db', 'cache_schema.rb'))).to be false
        expect(File.exist?(File.join(project_dir, 'db', 'queue_schema.rb'))).to be false
        expect(File.exist?(File.join(project_dir, 'db', 'cable_schema.rb'))).to be false
      end
    end

    context 'when cleanup is not needed (all non-solid)' do
      let(:resolved_backends) { { active_job: 'sidekiq', action_cable: 'redis', rails_cache: 'redis' } }

      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
      end

      it 'does not modify Gemfile' do
        original = File.read(File.join(project_dir, 'Gemfile'))
        setup.execute(resolved_backends: resolved_backends)
        expect(File.read(File.join(project_dir, 'Gemfile'))).to eq(original)
      end
    end

    context 'when cleanup is not needed (all solid)' do
      let(:resolved_backends) { { active_job: 'solid_queue', action_cable: 'solid_cable', rails_cache: 'solid_cache' } }

      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'solid_queue'\ngem 'solid_cable'\ngem 'solid_cache'\n")
      end

      it 'does not modify Gemfile' do
        original = File.read(File.join(project_dir, 'Gemfile'))
        setup.execute(resolved_backends: resolved_backends)
        expect(File.read(File.join(project_dir, 'Gemfile'))).to eq(original)
      end
    end

    context 'with Rails 7.2 recipe (no solid support)' do
      let(:recipe) { Moduloproject::Recipe.load('7.2') }
      let(:resolved_backends) { { active_job: 'solid_queue', action_cable: 'redis', rails_cache: 'redis' } }

      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
      end

      it 'does not run cleanup' do
        original = File.read(File.join(project_dir, 'Gemfile'))
        setup.execute(resolved_backends: resolved_backends)
        expect(File.read(File.join(project_dir, 'Gemfile'))).to eq(original)
      end
    end

    context 'when Gemfile does not exist' do
      let(:resolved_backends) { { active_job: 'solid_queue', action_cable: 'redis', rails_cache: 'redis' } }

      it 'does not raise error' do
        expect { setup.execute(resolved_backends: resolved_backends) }.not_to raise_error
      end
    end
  end
end
