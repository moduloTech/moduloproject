# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/commands/new'
require 'moduloproject/rails_generator'
require 'moduloproject/modulorails_setup'
require 'moduloproject/vite_setup'

RSpec.describe Moduloproject::Commands::New do
  let(:app_name) { 'test-app' }
  let(:default_options) { {} }
  let(:command) { described_class.new(app_name, default_options) }

  before do
    allow_any_instance_of(described_class).to receive(:display_success)
  end

  describe '#initialize' do
    it 'stores the name' do
      expect(command.name).to eq('test-app')
    end

    it 'merges options with defaults' do
      expect(command.options[:database]).to eq('postgresql')
      expect(command.options[:frontend]).to eq('vue')
      expect(command.options[:skip_docker]).to be false
    end

    it 'does not set ruby or rails by default (resolved from recipe)' do
      expect(command.options[:ruby]).to be_nil
      expect(command.options[:rails]).to be_nil
    end

    context 'with custom options' do
      let(:default_options) { { frontend: 'hotwire' } }

      it 'overrides defaults' do
        expect(command.options[:frontend]).to eq('hotwire')
      end
    end

    context 'with string keys' do
      let(:default_options) { { 'frontend' => 'hotwire' } }

      it 'converts to symbols' do
        expect(command.options[:frontend]).to eq('hotwire')
      end
    end
  end

  describe '#execute' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:recipe) { instance_double(Moduloproject::Recipe) }
    let(:rails_generator) { instance_double(Moduloproject::RailsGenerator) }
    let(:active_job_setup) { instance_double(Moduloproject::Setup::ActiveJobSetup) }
    let(:action_cable_setup) { instance_double(Moduloproject::Setup::ActionCableSetup) }
    let(:rails_cache_setup) { instance_double(Moduloproject::Setup::RailsCacheSetup) }
    let(:solid_cleanup) { instance_double(Moduloproject::Setup::SolidCleanup) }
    let(:modulorails_setup) { instance_double(Moduloproject::ModulorailsSetup) }
    let(:vite_setup) { instance_double(Moduloproject::ViteSetup) }

    before do
      Dir.chdir(tmpdir)
      allow(Moduloproject::Recipe).to receive_messages(latest_version: '8.1', load: recipe)
      allow(recipe).to receive(:backend_for).with(:active_job).and_return('sidekiq')
      allow(recipe).to receive(:backend_for).with(:action_cable).and_return('redis')
      allow(recipe).to receive(:backend_for).with(:rails_cache).and_return('redis')
      allow(recipe).to receive_messages(default_ruby: '4', validate_ruby!: true,
                                        available_backends_for: %w[sidekiq solid_queue])

      allow(Moduloproject::RailsGenerator).to receive(:new).and_return(rails_generator)
      allow(rails_generator).to receive(:generate)
      allow(Moduloproject::Setup::ActiveJobSetup).to receive(:new).and_return(active_job_setup)
      allow(active_job_setup).to receive(:execute)
      allow(Moduloproject::Setup::ActionCableSetup).to receive(:new).and_return(action_cable_setup)
      allow(action_cable_setup).to receive(:execute)
      allow(Moduloproject::Setup::RailsCacheSetup).to receive(:new).and_return(rails_cache_setup)
      allow(rails_cache_setup).to receive(:execute)
      allow(Moduloproject::Setup::SolidCleanup).to receive(:new).and_return(solid_cleanup)
      allow(solid_cleanup).to receive(:execute)
      allow(Moduloproject::ModulorailsSetup).to receive(:new).and_return(modulorails_setup)
      allow(modulorails_setup).to receive(:execute)
      allow(Moduloproject::ViteSetup).to receive(:new).and_return(vite_setup)
      allow(vite_setup).to receive(:execute)
      allow(Moduloproject::Generators).to receive(:run_all)
      allow_any_instance_of(described_class).to receive(:system).and_return(true)
    end

    after do
      Dir.chdir('/')
      FileUtils.rm_rf(tmpdir)
    end

    it 'creates project directory' do
      command.execute
      expect(Dir.exist?(File.join(tmpdir, app_name))).to be true
    end

    it 'loads the recipe for the latest Rails version by default' do
      expect(Moduloproject::Recipe).to receive(:latest_version).and_return('8.1')
      expect(Moduloproject::Recipe).to receive(:load).with('8.1')
      command.execute
    end

    it 'resolves ruby version from recipe' do
      expect(recipe).to receive(:default_ruby).and_return('4')
      command.execute
      expect(command.options[:ruby]).to eq('4')
    end

    it 'calls RailsGenerator with recipe' do
      expect(Moduloproject::RailsGenerator).to receive(:new).with(app_name, hash_including(:ruby, :frontend),
                                                                  recipe: recipe)
      expect(rails_generator).to receive(:generate)
      command.execute
    end

    it 'calls ActiveJobSetup with recipe' do
      expect(Moduloproject::Setup::ActiveJobSetup).to receive(:new).with(app_name, hash_including(:frontend),
                                                                         recipe: recipe)
      expect(active_job_setup).to receive(:execute)
      command.execute
    end

    it 'calls ActionCableSetup with recipe' do
      expect(Moduloproject::Setup::ActionCableSetup).to receive(:new).with(app_name, hash_including(:frontend),
                                                                           recipe: recipe)
      expect(action_cable_setup).to receive(:execute)
      command.execute
    end

    it 'calls RailsCacheSetup with recipe' do
      expect(Moduloproject::Setup::RailsCacheSetup).to receive(:new).with(app_name, hash_including(:frontend),
                                                                          recipe: recipe)
      expect(rails_cache_setup).to receive(:execute)
      command.execute
    end

    it 'calls SolidCleanup with recipe and resolved_backends' do
      expect(Moduloproject::Setup::SolidCleanup).to receive(:new).with(app_name, hash_including(:frontend),
                                                                       recipe: recipe)
      expect(solid_cleanup).to receive(:execute).with(resolved_backends: { active_job: 'sidekiq',
                                                                           action_cable: 'redis', rails_cache: 'redis' })
      command.execute
    end

    it 'calls ModulorailsSetup' do
      expect(Moduloproject::ModulorailsSetup).to receive(:new).with(app_name, hash_including(:ruby))
      expect(modulorails_setup).to receive(:execute)
      command.execute
    end

    it 'calls ViteSetup' do
      expect(Moduloproject::ViteSetup).to receive(:new).with(app_name, hash_including(:ruby))
      expect(vite_setup).to receive(:execute)
      command.execute
    end

    it 'calls Generators.run_all with context' do
      expect(Moduloproject::Generators).to receive(:run_all) do |context, _opts|
        expect(context).to be_a(Moduloproject::Context)
        expect(context.project_name).to eq(app_name)
      end
      command.execute
    end

    it 'passes frontend to context' do
      expect(Moduloproject::Generators).to receive(:run_all) do |context, _opts|
        expect(context.frontend).to eq('vue')
      end
      command.execute
    end

    context 'with skip_docker option' do
      let(:default_options) { { skip_docker: true } }

      it 'skips infrastructure generation' do
        expect(Moduloproject::Generators).not_to receive(:run_all)
        command.execute
      end
    end

    context 'with hotwire frontend' do
      let(:default_options) { { frontend: 'hotwire' } }

      it 'passes importmap js_engine to context' do
        expect(Moduloproject::Generators).to receive(:run_all) do |context, _opts|
          expect(context.js_engine).to eq(:importmap)
        end
        command.execute
      end
    end

    context 'with explicit ruby version' do
      let(:default_options) { { ruby: '3.3' } }

      it 'uses the specified ruby version' do
        command.execute
        expect(command.options[:ruby]).to eq('3.3')
      end

      it 'validates ruby against recipe' do
        expect(recipe).to receive(:validate_ruby!).with('3.3')
        command.execute
      end
    end

    context 'with explicit backend options' do
      let(:default_options) { { active_job: 'solid_queue' } }

      before do
        allow(recipe).to receive(:available_backends_for).with(:active_job).and_return(%w[sidekiq solid_queue])
        allow(recipe).to receive(:available_backends_for).with(:action_cable).and_return(%w[redis solid_cable])
        allow(recipe).to receive(:available_backends_for).with(:rails_cache).and_return(%w[redis solid_cache])
      end

      it 'passes backend to setup' do
        expect(Moduloproject::Setup::ActiveJobSetup).to receive(:new).with(
          app_name, hash_including(active_job: 'solid_queue'), recipe: recipe
        )
        command.execute
      end
    end

    context 'with invalid backend' do
      let(:default_options) { { active_job: 'resque' } }

      before do
        allow(recipe).to receive(:available_backends_for).with(:active_job).and_return(%w[sidekiq solid_queue])
        allow(recipe).to receive(:available_backends_for).with(:action_cable).and_return(%w[redis solid_cable])
        allow(recipe).to receive(:available_backends_for).with(:rails_cache).and_return(%w[redis solid_cache])
      end

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Invalid active_job backend/)
      end
    end

    context 'when recipe is not found' do
      let(:default_options) { { rails: '99.0' } }

      before do
        allow(Moduloproject::Recipe).to receive(:load).and_call_original
      end

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Recipe not found/)
      end
    end

    context 'when ruby is incompatible' do
      before do
        allow(recipe).to receive(:validate_ruby!).and_raise(
          Moduloproject::Recipe::IncompatibleVersionError, 'Ruby 4 exceeds maximum 3.3'
        )
      end

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /exceeds maximum/)
      end
    end
  end

  describe 'name validation' do
    context 'with nil name' do
      let(:app_name) { nil }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, 'Project name required')
      end
    end

    context 'with empty name' do
      let(:app_name) { '' }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, 'Project name required')
      end
    end

    context 'with invalid name starting with number' do
      let(:app_name) { '123app' }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Invalid project name/)
      end
    end

    context 'with invalid name containing spaces' do
      let(:app_name) { 'my app' }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Invalid project name/)
      end
    end

    context 'with invalid name containing uppercase' do
      let(:app_name) { 'MyApp' }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Invalid project name/)
      end
    end

    context 'with valid name using hyphens' do
      let(:app_name) { 'my-cool-app' }
      let(:tmpdir) { Dir.mktmpdir }
      let(:recipe) { instance_double(Moduloproject::Recipe) }

      before do
        Dir.chdir(tmpdir)
        allow(Moduloproject::Recipe).to receive_messages(latest_version: '8.1', load: recipe)
        allow(recipe).to receive_messages(default_ruby: '4', validate_ruby!: true, backend_for: 'sidekiq',
                                          available_backends_for: %w[sidekiq solid_queue])
        allow(Moduloproject::RailsGenerator).to receive(:new).and_return(instance_double(Moduloproject::RailsGenerator,
                                                                                         generate: nil))
        allow(Moduloproject::Setup::ActiveJobSetup).to receive(:new).and_return(instance_double(
                                                                                  Moduloproject::Setup::ActiveJobSetup, execute: nil
                                                                                ))
        allow(Moduloproject::Setup::ActionCableSetup).to receive(:new).and_return(instance_double(
                                                                                    Moduloproject::Setup::ActionCableSetup, execute: nil
                                                                                  ))
        allow(Moduloproject::Setup::RailsCacheSetup).to receive(:new).and_return(instance_double(
                                                                                   Moduloproject::Setup::RailsCacheSetup, execute: nil
                                                                                 ))
        allow(Moduloproject::Setup::SolidCleanup).to receive(:new).and_return(instance_double(
                                                                                Moduloproject::Setup::SolidCleanup, execute: nil
                                                                              ))
        allow(Moduloproject::ModulorailsSetup).to receive(:new).and_return(instance_double(
                                                                             Moduloproject::ModulorailsSetup, execute: nil
                                                                           ))
        allow(Moduloproject::ViteSetup).to receive(:new).and_return(instance_double(Moduloproject::ViteSetup,
                                                                                    execute: nil))
        allow(Moduloproject::Generators).to receive(:run_all)
        allow_any_instance_of(described_class).to receive(:system).and_return(true)
      end

      after do
        Dir.chdir('/')
        FileUtils.rm_rf(tmpdir)
      end

      it 'does not raise' do
        expect { command.execute }.not_to raise_error
      end
    end

    context 'with valid name using underscores' do
      let(:app_name) { 'my_cool_app' }
      let(:tmpdir) { Dir.mktmpdir }
      let(:recipe) { instance_double(Moduloproject::Recipe) }

      before do
        Dir.chdir(tmpdir)
        allow(Moduloproject::Recipe).to receive_messages(latest_version: '8.1', load: recipe)
        allow(recipe).to receive_messages(default_ruby: '4', validate_ruby!: true, backend_for: 'sidekiq',
                                          available_backends_for: %w[sidekiq solid_queue])
        allow(Moduloproject::RailsGenerator).to receive(:new).and_return(instance_double(Moduloproject::RailsGenerator,
                                                                                         generate: nil))
        allow(Moduloproject::Setup::ActiveJobSetup).to receive(:new).and_return(instance_double(
                                                                                  Moduloproject::Setup::ActiveJobSetup, execute: nil
                                                                                ))
        allow(Moduloproject::Setup::ActionCableSetup).to receive(:new).and_return(instance_double(
                                                                                    Moduloproject::Setup::ActionCableSetup, execute: nil
                                                                                  ))
        allow(Moduloproject::Setup::RailsCacheSetup).to receive(:new).and_return(instance_double(
                                                                                   Moduloproject::Setup::RailsCacheSetup, execute: nil
                                                                                 ))
        allow(Moduloproject::Setup::SolidCleanup).to receive(:new).and_return(instance_double(
                                                                                Moduloproject::Setup::SolidCleanup, execute: nil
                                                                              ))
        allow(Moduloproject::ModulorailsSetup).to receive(:new).and_return(instance_double(
                                                                             Moduloproject::ModulorailsSetup, execute: nil
                                                                           ))
        allow(Moduloproject::ViteSetup).to receive(:new).and_return(instance_double(Moduloproject::ViteSetup,
                                                                                    execute: nil))
        allow(Moduloproject::Generators).to receive(:run_all)
        allow_any_instance_of(described_class).to receive(:system).and_return(true)
      end

      after do
        Dir.chdir('/')
        FileUtils.rm_rf(tmpdir)
      end

      it 'does not raise' do
        expect { command.execute }.not_to raise_error
      end
    end
  end

  describe 'options validation' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:recipe) { instance_double(Moduloproject::Recipe) }

    before do
      Dir.chdir(tmpdir)
      allow(Moduloproject::Recipe).to receive_messages(latest_version: '8.1', load: recipe)
      allow(recipe).to receive_messages(default_ruby: '4', validate_ruby!: true,
                                        available_backends_for: %w[sidekiq solid_queue])
    end

    after do
      Dir.chdir('/')
      FileUtils.rm_rf(tmpdir)
    end

    context 'with invalid database' do
      let(:default_options) { { database: 'oracle' } }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Invalid database/)
      end
    end

    context 'with invalid frontend' do
      let(:default_options) { { frontend: 'react' } }

      it 'raises ArgumentError' do
        expect { command.execute }.to raise_error(ArgumentError, /Invalid frontend/)
      end
    end
  end

  describe 'directory validation' do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      Dir.chdir(tmpdir)
      FileUtils.mkdir_p(app_name)
      allow(Moduloproject::Recipe).to receive_messages(latest_version: '8.1',
                                                       load: instance_double(
                                                         Moduloproject::Recipe, default_ruby: '4', validate_ruby!: true, available_backends_for: []
                                                       ))
    end

    after do
      Dir.chdir('/')
      FileUtils.rm_rf(tmpdir)
    end

    it 'raises ArgumentError if directory exists' do
      expect { command.execute }.to raise_error(ArgumentError, /Directory already exists/)
    end
  end
end
