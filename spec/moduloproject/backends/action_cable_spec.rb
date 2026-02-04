# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/backends/action_cable'
require 'moduloproject/backends/action_cable/redis'
require 'moduloproject/backends/action_cable/solid_cable'

RSpec.describe Moduloproject::Backends::ActionCable do
  describe '.for' do
    it 'returns Redis strategy class' do
      expect(described_class.for('redis')).to eq(described_class::Redis)
    end

    it 'returns SolidCable strategy class' do
      expect(described_class.for('solid_cable')).to eq(described_class::SolidCable)
    end

    it 'raises for unknown backend' do
      expect { described_class.for('unknown') }
        .to raise_error(ArgumentError, /Unknown Action Cable backend/)
    end
  end

  describe '.available' do
    it 'lists registered backends' do
      expect(described_class.available).to include('redis', 'solid_cable')
    end
  end
end

RSpec.describe Moduloproject::Backends::ActionCable::Redis do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1' } }
  let(:strategy) { described_class.new(name, options) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmpdir, name) }

  before do
    FileUtils.mkdir_p(File.join(project_dir, 'config'))
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

  describe '#adapter_name' do
    it 'returns :redis' do
      expect(strategy.adapter_name).to eq(:redis)
    end
  end

  describe '#apply' do
    before do
      File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
    end

    it 'creates cable.yml with Redis adapter for all environments' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'cable.yml'))
      expect(content.scan('adapter: redis').count).to eq(3)
    end

    it 'includes REDIS_URL for all environments' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'cable.yml'))
      expect(content.scan('REDIS_URL').count).to eq(3)
    end

    it 'includes channel_prefix for each environment' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'cable.yml'))
      expect(content).to include('test_app_development')
      expect(content).to include('test_app_test')
      expect(content).to include('test_app_production')
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

    context 'when Gemfile does not exist' do
      before { FileUtils.rm_f(File.join(project_dir, 'Gemfile')) }

      it 'does not raise error' do
        expect { strategy.apply }.not_to raise_error
      end
    end
  end
end

RSpec.describe Moduloproject::Backends::ActionCable::SolidCable do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1' } }
  let(:strategy) { described_class.new(name, options) }

  describe '#gem_name' do
    it 'returns solid_cable' do
      expect(strategy.gem_name).to eq('solid_cable')
    end
  end

  describe '#adapter_name' do
    it 'returns :solid_cable' do
      expect(strategy.adapter_name).to eq(:solid_cable)
    end
  end

  describe '#apply' do
    it 'is a no-op' do
      expect { strategy.apply }.not_to raise_error
    end
  end
end
