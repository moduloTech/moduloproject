# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/backends/rails_cache'
require 'moduloproject/backends/rails_cache/redis'
require 'moduloproject/backends/rails_cache/solid_cache'

RSpec.describe Moduloproject::Backends::RailsCache do
  describe '.for' do
    it 'returns Redis strategy class' do
      expect(described_class.for('redis')).to eq(described_class::Redis)
    end

    it 'returns SolidCache strategy class' do
      expect(described_class.for('solid_cache')).to eq(described_class::SolidCache)
    end

    it 'raises for unknown backend' do
      expect { described_class.for('unknown') }
        .to raise_error(ArgumentError, /Unknown Rails cache backend/)
    end
  end

  describe '.available' do
    it 'lists registered backends' do
      expect(described_class.available).to include('redis', 'solid_cache')
    end
  end
end

RSpec.describe Moduloproject::Backends::RailsCache::Redis do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1' } }
  let(:strategy) { described_class.new(name, options) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmpdir, name) }

  before do
    FileUtils.mkdir_p(File.join(project_dir, 'config', 'environments'))
    Dir.chdir(tmpdir)
  end

  after do
    Dir.chdir('/')
    FileUtils.rm_rf(tmpdir)
  end

  describe '#gem_name' do
    it 'returns redis' do
      expect(strategy.gem_name).to eq('redis')
    end
  end

  describe '#store_name' do
    it 'returns :redis_cache_store' do
      expect(strategy.store_name).to eq(:redis_cache_store)
    end
  end

  describe '#apply' do
    before do
      File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
      File.write(File.join(project_dir, 'config', 'environments', 'production.rb'), <<~RUBY)
        Rails.application.configure do
          config.cache_store = :solid_cache_store
        end
      RUBY
      File.write(File.join(project_dir, 'config', 'application.rb'), <<~RUBY)
        module TestApp
          class Application < Rails::Application
          end
        end
      RUBY
    end

    it 'removes solid_cache_store from production.rb' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'environments', 'production.rb'))
      expect(content).not_to include(':solid_cache_store')
    end

    it 'adds redis_cache_store to application.rb' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'application.rb'))
      expect(content).to include(':redis_cache_store')
    end

    it 'includes REDIS_URL in application.rb' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'application.rb'))
      expect(content).to include('REDIS_URL')
    end

    it 'adds redis gem to Gemfile' do
      strategy.apply
      content = File.read(File.join(project_dir, 'Gemfile'))
      expect(content).to include("gem 'redis'")
    end

    it 'does not duplicate redis gem' do
      File.write(File.join(project_dir, 'Gemfile'), "gem 'redis'\n")
      strategy.apply
      content = File.read(File.join(project_dir, 'Gemfile'))
      expect(content.scan("gem 'redis'").count).to eq(1)
    end

    it 'does not duplicate redis_cache_store if already present' do
      File.write(File.join(project_dir, 'config', 'application.rb'), <<~RUBY)
        module TestApp
          class Application < Rails::Application
            config.cache_store = :redis_cache_store
          end
        end
      RUBY
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'application.rb'))
      expect(content.scan(':redis_cache_store').count).to eq(1)
    end

    context 'when production.rb does not exist' do
      before { FileUtils.rm_f(File.join(project_dir, 'config', 'environments', 'production.rb')) }

      it 'does not raise error' do
        expect { strategy.apply }.not_to raise_error
      end
    end

    context 'when application.rb does not exist' do
      before { FileUtils.rm_f(File.join(project_dir, 'config', 'application.rb')) }

      it 'does not raise error' do
        expect { strategy.apply }.not_to raise_error
      end
    end

    context 'when Gemfile does not exist' do
      before { FileUtils.rm_f(File.join(project_dir, 'Gemfile')) }

      it 'does not raise error' do
        expect { strategy.apply }.not_to raise_error
      end
    end
  end
end

RSpec.describe Moduloproject::Backends::RailsCache::SolidCache do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1' } }
  let(:strategy) { described_class.new(name, options) }

  describe '#gem_name' do
    it 'returns solid_cache' do
      expect(strategy.gem_name).to eq('solid_cache')
    end
  end

  describe '#store_name' do
    it 'returns :solid_cache_store' do
      expect(strategy.store_name).to eq(:solid_cache_store)
    end
  end

  describe '#apply' do
    it 'is a no-op' do
      expect { strategy.apply }.not_to raise_error
    end
  end
end
