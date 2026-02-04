# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/recipe'
require 'moduloproject/backends/rails_cache'
require 'moduloproject/backends/rails_cache/redis'
require 'moduloproject/backends/rails_cache/solid_cache'
require 'moduloproject/setup/rails_cache_setup'

RSpec.describe Moduloproject::Setup::RailsCacheSetup do
  let(:name) { 'test-app' }
  let(:options) { {} }
  let(:recipe) { Moduloproject::Recipe.load('8.1') }
  let(:setup) { described_class.new(name, options, recipe: recipe) }

  before { allow(setup).to receive(:puts) }

  describe '#execute' do
    let(:strategy) { instance_double(Moduloproject::Backends::RailsCache::Redis) }

    before do
      allow(Moduloproject::Backends::RailsCache::Redis).to receive(:new).and_return(strategy)
      allow(strategy).to receive(:apply)
    end

    context 'with default backend from recipe' do
      it 'uses redis (recipe default)' do
        expect(Moduloproject::Backends::RailsCache::Redis).to receive(:new).with(name, options)
        expect(strategy).to receive(:apply)
        setup.execute
      end
    end

    context 'with explicit backend in options' do
      let(:options) { { rails_cache: 'solid_cache' } }
      let(:sc_strategy) { instance_double(Moduloproject::Backends::RailsCache::SolidCache) }

      before do
        allow(Moduloproject::Backends::RailsCache::SolidCache).to receive(:new).and_return(sc_strategy)
        allow(sc_strategy).to receive(:apply)
      end

      it 'uses the specified backend' do
        expect(Moduloproject::Backends::RailsCache::SolidCache).to receive(:new).with(name, options)
        expect(sc_strategy).to receive(:apply)
        setup.execute
      end
    end
  end
end
