# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/recipe'

RSpec.describe Moduloproject::Recipe do
  let(:recipes_dir) { File.expand_path('../../recipes', __dir__) }

  describe '.available_versions' do
    it 'returns sorted list of available Rails versions' do
      versions = described_class.available_versions(recipes_dir: recipes_dir)
      expect(versions).to eq(%w[7.2 8.0 8.1])
    end

    it 'returns versions sorted by Gem::Version' do
      versions = described_class.available_versions(recipes_dir: recipes_dir)
      expect(versions.first).to eq('7.2')
      expect(versions.last).to eq('8.1')
    end
  end

  describe '.latest_version' do
    it 'returns the highest available version' do
      expect(described_class.latest_version(recipes_dir: recipes_dir)).to eq('8.1')
    end
  end

  describe '.load' do
    it 'returns a Recipe instance' do
      recipe = described_class.load('8.1', recipes_dir: recipes_dir)
      expect(recipe).to be_a(described_class)
    end

    it 'raises RecipeNotFoundError for unknown version' do
      expect { described_class.load('99.0', recipes_dir: recipes_dir) }
        .to raise_error(described_class::RecipeNotFoundError, /rails-99\.0/)
    end
  end

  describe 'Rails 8.1 recipe' do
    let(:recipe) { described_class.load('8.1', recipes_dir: recipes_dir) }

    describe '#default_ruby' do
      it 'returns 4' do
        expect(recipe.default_ruby).to eq('4')
      end
    end

    describe '#validate_ruby!' do
      it 'passes for Ruby 3.3' do
        expect(recipe.validate_ruby!('3.3')).to be true
      end

      it 'passes for Ruby 4' do
        expect(recipe.validate_ruby!('4')).to be true
      end

      it 'passes for Ruby 3.2' do
        expect(recipe.validate_ruby!('3.2')).to be true
      end

      it 'raises for Ruby 3.1' do
        expect { recipe.validate_ruby!('3.1') }
          .to raise_error(described_class::IncompatibleVersionError, /below minimum/)
      end
    end

    describe '#backend_for' do
      it 'returns sidekiq for active_job' do
        expect(recipe.backend_for(:active_job)).to eq('sidekiq')
      end

      it 'returns redis for action_cable' do
        expect(recipe.backend_for(:action_cable)).to eq('redis')
      end

      it 'returns redis for rails_cache' do
        expect(recipe.backend_for(:rails_cache)).to eq('redis')
      end
    end

    describe '#available_backends_for' do
      it 'returns sidekiq and solid_queue for active_job' do
        expect(recipe.available_backends_for(:active_job)).to eq(%w[sidekiq solid_queue])
      end

      it 'returns redis and solid_cable for action_cable' do
        expect(recipe.available_backends_for(:action_cable)).to eq(%w[redis solid_cable])
      end

      it 'returns redis and solid_cache for rails_cache' do
        expect(recipe.available_backends_for(:rails_cache)).to eq(%w[redis solid_cache])
      end

      it 'returns empty array for unknown concern' do
        expect(recipe.available_backends_for(:unknown)).to eq([])
      end
    end

    describe '#rails_options' do
      context 'with vue frontend and all non-solid backends' do
        it 'includes --skip-solid' do
          opts = recipe.rails_options(
            frontend: 'vue',
            database: 'postgresql',
            resolved_backends: { active_job: 'sidekiq', action_cable: 'redis', rails_cache: 'redis' }
          )
          expect(opts).to include('--skip-solid')
          expect(opts).to include('--database=postgresql')
          expect(opts).to include('--skip-javascript')
          expect(opts).to include('--skip-test')
          expect(opts).to include('--skip-system-test')
          expect(opts).to include('--skip-docker')
        end
      end

      context 'with hotwire frontend' do
        it 'includes importmap and bootstrap options' do
          opts = recipe.rails_options(
            frontend: 'hotwire',
            database: 'postgresql',
            resolved_backends: { active_job: 'sidekiq', action_cable: 'redis', rails_cache: 'redis' }
          )
          expect(opts).to include('--javascript=importmap')
          expect(opts).to include('--css=bootstrap')
          expect(opts).not_to include('--skip-javascript')
        end
      end

      context 'with one solid backend' do
        it 'does NOT include --skip-solid' do
          opts = recipe.rails_options(
            frontend: 'vue',
            database: 'postgresql',
            resolved_backends: { active_job: 'solid_queue', action_cable: 'redis', rails_cache: 'redis' }
          )
          expect(opts).not_to include('--skip-solid')
        end
      end

      context 'with empty resolved_backends' do
        it 'does not include --skip-solid' do
          opts = recipe.rails_options(
            frontend: 'vue',
            database: 'postgresql',
            resolved_backends: {}
          )
          expect(opts).not_to include('--skip-solid')
        end
      end
    end

    describe '#supports_skip_solid?' do
      it 'returns true' do
        expect(recipe.supports_skip_solid?).to be true
      end
    end

    describe '#needs_solid_cleanup?' do
      it 'returns true when mixed solid and non-solid backends' do
        expect(recipe.needs_solid_cleanup?(
                 active_job: 'solid_queue', action_cable: 'redis', rails_cache: 'redis'
               )).to be true
      end

      it 'returns false when all non-solid' do
        expect(recipe.needs_solid_cleanup?(
                 active_job: 'sidekiq', action_cable: 'redis', rails_cache: 'redis'
               )).to be false
      end

      it 'returns false when all solid' do
        expect(recipe.needs_solid_cleanup?(
                 active_job: 'solid_queue', action_cable: 'solid_cable', rails_cache: 'solid_cache'
               )).to be false
      end
    end

    describe '#solid_files' do
      it 'returns the list of solid config files' do
        expect(recipe.solid_files).to include('config/cache.yml', 'config/queue.yml')
      end
    end

    describe '#solid_backend_gems' do
      it 'returns the mapping of solid backends to gems' do
        expect(recipe.solid_backend_gems).to eq(
          'solid_queue' => 'solid_queue',
          'solid_cable' => 'solid_cable',
          'solid_cache' => 'solid_cache'
        )
      end
    end
  end

  describe 'Rails 8.0 recipe (inherits from 8.1)' do
    let(:recipe) { described_class.load('8.0', recipes_dir: recipes_dir) }

    it 'overrides ruby compatibility' do
      expect(recipe.default_ruby).to eq('3.4')
    end

    it 'validates Ruby within range' do
      expect(recipe.validate_ruby!('3.2')).to be true
      expect(recipe.validate_ruby!('3.4')).to be true
    end

    it 'rejects Ruby above maximum' do
      expect { recipe.validate_ruby!('4') }
        .to raise_error(described_class::IncompatibleVersionError, /exceeds maximum/)
    end

    it 'rejects Ruby below minimum' do
      expect { recipe.validate_ruby!('3.1') }
        .to raise_error(described_class::IncompatibleVersionError, /below minimum/)
    end

    it 'inherits backend_defaults from 8.1' do
      expect(recipe.backend_for(:active_job)).to eq('sidekiq')
    end

    it 'inherits available_backends from 8.1' do
      expect(recipe.available_backends_for(:active_job)).to eq(%w[sidekiq solid_queue])
    end

    it 'inherits frontend options from 8.1' do
      opts = recipe.rails_options(
        frontend: 'vue',
        database: 'postgresql',
        resolved_backends: { active_job: 'sidekiq', action_cable: 'redis', rails_cache: 'redis' }
      )
      expect(opts).to include('--skip-javascript')
    end

    it 'supports skip_solid' do
      expect(recipe.supports_skip_solid?).to be true
    end

    it 'overrides common rails_options' do
      opts = recipe.rails_options(
        frontend: 'vue',
        database: 'postgresql',
        resolved_backends: { active_job: 'sidekiq' }
      )
      expect(opts).to include('--database=postgresql')
      expect(opts).to include('--skip-test')
    end
  end

  describe 'Rails 7.2 recipe (inherits from 8.0)' do
    let(:recipe) { described_class.load('7.2', recipes_dir: recipes_dir) }

    it 'overrides ruby compatibility' do
      expect(recipe.default_ruby).to eq('3.4')
    end

    it 'validates Ruby 3.1' do
      expect(recipe.validate_ruby!('3.1')).to be true
    end

    it 'rejects Ruby 4' do
      expect { recipe.validate_ruby!('4') }
        .to raise_error(described_class::IncompatibleVersionError, /exceeds maximum/)
    end

    it 'rejects Ruby 3.0' do
      expect { recipe.validate_ruby!('3.0') }
        .to raise_error(described_class::IncompatibleVersionError, /below minimum/)
    end

    it 'does not support skip_solid' do
      expect(recipe.supports_skip_solid?).to be false
    end

    it 'never includes --skip-solid in rails_options' do
      opts = recipe.rails_options(
        frontend: 'vue',
        database: 'postgresql',
        resolved_backends: { active_job: 'sidekiq', action_cable: 'redis', rails_cache: 'redis' }
      )
      expect(opts).not_to include('--skip-solid')
    end

    it 'has empty solid_backend_gems' do
      expect(recipe.solid_backend_gems).to eq({})
    end

    it 'has empty solid_files' do
      expect(recipe.solid_files).to eq([])
    end

    it 'never needs solid cleanup' do
      expect(recipe.needs_solid_cleanup?(
               active_job: 'solid_queue', action_cable: 'redis', rails_cache: 'redis'
             )).to be false
    end

    it 'inherits backend_defaults from parent chain' do
      expect(recipe.backend_for(:active_job)).to eq('sidekiq')
    end
  end

  describe 'circular inheritance detection' do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      File.write(File.join(tmpdir, 'rails-a.yml'), "inherits_from: rails-b\n")
      File.write(File.join(tmpdir, 'rails-b.yml'), "inherits_from: rails-a\n")
    end

    after { FileUtils.rm_rf(tmpdir) }

    it 'raises CircularInheritanceError' do
      expect { described_class.load('a', recipes_dir: tmpdir) }
        .to raise_error(described_class::CircularInheritanceError)
    end
  end

  describe 'deep merge behavior' do
    let(:recipe) { described_class.load('8.0', recipes_dir: recipes_dir) }

    it 'child overrides common rails_options from parent' do
      opts = recipe.rails_options(frontend: 'vue', database: 'mysql2', resolved_backends: {})
      expect(opts).to include('--database=mysql')
    end

    it 'child inherits frontend options from parent' do
      opts = recipe.rails_options(frontend: 'hotwire', database: 'postgresql', resolved_backends: {})
      expect(opts).to include('--javascript=importmap')
      expect(opts).to include('--css=bootstrap')
    end
  end
end
