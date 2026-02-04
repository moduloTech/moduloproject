# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/recipe'
require 'moduloproject/backends/active_job'
require 'moduloproject/backends/active_job/sidekiq'
require 'moduloproject/backends/active_job/solid_queue'
require 'moduloproject/setup/active_job_setup'

RSpec.describe Moduloproject::Setup::ActiveJobSetup do
  let(:name) { 'test-app' }
  let(:options) { {} }
  let(:recipe) { Moduloproject::Recipe.load('8.1') }
  let(:setup) { described_class.new(name, options, recipe: recipe) }

  before { allow(setup).to receive(:puts) }

  describe '#execute' do
    let(:strategy) { instance_double(Moduloproject::Backends::ActiveJob::Sidekiq) }

    before do
      allow(Moduloproject::Backends::ActiveJob::Sidekiq).to receive(:new).and_return(strategy)
      allow(strategy).to receive(:apply)
    end

    context 'with default backend from recipe' do
      it 'uses sidekiq (recipe default)' do
        expect(Moduloproject::Backends::ActiveJob::Sidekiq).to receive(:new).with(name, options)
        expect(strategy).to receive(:apply)
        setup.execute
      end
    end

    context 'with explicit backend in options' do
      let(:options) { { active_job: 'solid_queue' } }
      let(:sq_strategy) { instance_double(Moduloproject::Backends::ActiveJob::SolidQueue) }

      before do
        allow(Moduloproject::Backends::ActiveJob::SolidQueue).to receive(:new).and_return(sq_strategy)
        allow(sq_strategy).to receive(:apply)
      end

      it 'uses the specified backend' do
        expect(Moduloproject::Backends::ActiveJob::SolidQueue).to receive(:new).with(name, options)
        expect(sq_strategy).to receive(:apply)
        setup.execute
      end
    end
  end
end
