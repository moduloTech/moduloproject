# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/backends/active_job'
require 'moduloproject/backends/active_job/sidekiq'
require 'moduloproject/backends/active_job/solid_queue'

RSpec.describe Moduloproject::Backends::ActiveJob do
  describe '.for' do
    it 'returns Sidekiq strategy class' do
      expect(described_class.for('sidekiq')).to eq(described_class::Sidekiq)
    end

    it 'returns SolidQueue strategy class' do
      expect(described_class.for('solid_queue')).to eq(described_class::SolidQueue)
    end

    it 'raises for unknown backend' do
      expect { described_class.for('unknown') }
        .to raise_error(ArgumentError, /Unknown Active Job backend/)
    end
  end

  describe '.available' do
    it 'lists registered backends' do
      expect(described_class.available).to include('sidekiq', 'solid_queue')
    end
  end
end

RSpec.describe Moduloproject::Backends::ActiveJob::Sidekiq do
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
    it 'returns sidekiq' do
      expect(strategy.gem_name).to eq('sidekiq')
    end
  end

  describe '#adapter_name' do
    it 'returns :sidekiq' do
      expect(strategy.adapter_name).to eq(:sidekiq)
    end
  end

  describe '#apply' do
    before do
      File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
      File.write(File.join(project_dir, 'config', 'application.rb'), <<~RUBY)
        module TestApp
          class Application < Rails::Application
            config.active_job.queue_adapter = :solid_queue
          end
        end
      RUBY
    end

    it 'replaces solid_queue with sidekiq in application.rb' do
      strategy.apply
      content = File.read(File.join(project_dir, 'config', 'application.rb'))
      expect(content).to include(':sidekiq')
      expect(content).not_to include(':solid_queue')
    end

    it 'adds sidekiq gem to Gemfile' do
      strategy.apply
      content = File.read(File.join(project_dir, 'Gemfile'))
      expect(content).to include("gem 'sidekiq'")
    end

    it 'adds redis gem to Gemfile' do
      strategy.apply
      content = File.read(File.join(project_dir, 'Gemfile'))
      expect(content).to include("gem 'redis'")
    end

    it 'does not duplicate sidekiq gem' do
      File.write(File.join(project_dir, 'Gemfile'), "gem 'sidekiq'\n")
      strategy.apply
      content = File.read(File.join(project_dir, 'Gemfile'))
      expect(content.scan("gem 'sidekiq'").count).to eq(1)
    end

    context 'when queue_adapter is not already set' do
      before do
        File.write(File.join(project_dir, 'config', 'application.rb'), <<~RUBY)
          module TestApp
            class Application < Rails::Application
            end
          end
        RUBY
      end

      it 'adds queue_adapter configuration' do
        strategy.apply
        content = File.read(File.join(project_dir, 'config', 'application.rb'))
        expect(content).to include('config.active_job.queue_adapter = :sidekiq')
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

RSpec.describe Moduloproject::Backends::ActiveJob::SolidQueue do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1' } }
  let(:strategy) { described_class.new(name, options) }

  describe '#gem_name' do
    it 'returns solid_queue' do
      expect(strategy.gem_name).to eq('solid_queue')
    end
  end

  describe '#adapter_name' do
    it 'returns :solid_queue' do
      expect(strategy.adapter_name).to eq(:solid_queue)
    end
  end

  describe '#apply' do
    it 'is a no-op' do
      expect { strategy.apply }.not_to raise_error
    end
  end
end
