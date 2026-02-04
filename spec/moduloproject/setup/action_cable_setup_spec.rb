# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/recipe'
require 'moduloproject/backends/action_cable'
require 'moduloproject/backends/action_cable/redis'
require 'moduloproject/backends/action_cable/solid_cable'
require 'moduloproject/setup/action_cable_setup'

RSpec.describe Moduloproject::Setup::ActionCableSetup do
  let(:name) { 'test-app' }
  let(:options) { {} }
  let(:recipe) { Moduloproject::Recipe.load('8.1') }
  let(:setup) { described_class.new(name, options, recipe: recipe) }

  before { allow(setup).to receive(:puts) }

  describe '#execute' do
    let(:strategy) { instance_double(Moduloproject::Backends::ActionCable::Redis) }

    before do
      allow(Moduloproject::Backends::ActionCable::Redis).to receive(:new).and_return(strategy)
      allow(strategy).to receive(:apply)
    end

    context 'with default backend from recipe' do
      it 'uses redis (recipe default)' do
        expect(Moduloproject::Backends::ActionCable::Redis).to receive(:new).with(name, options)
        expect(strategy).to receive(:apply)
        setup.execute
      end
    end

    context 'with explicit backend in options' do
      let(:options) { { action_cable: 'solid_cable' } }
      let(:sc_strategy) { instance_double(Moduloproject::Backends::ActionCable::SolidCable) }

      before do
        allow(Moduloproject::Backends::ActionCable::SolidCable).to receive(:new).and_return(sc_strategy)
        allow(sc_strategy).to receive(:apply)
      end

      it 'uses the specified backend' do
        expect(Moduloproject::Backends::ActionCable::SolidCable).to receive(:new).with(name, options)
        expect(sc_strategy).to receive(:apply)
        setup.execute
      end
    end
  end
end
