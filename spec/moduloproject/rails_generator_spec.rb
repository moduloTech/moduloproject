# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/rails_generator'

RSpec.describe Moduloproject::RailsGenerator do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1', database: 'postgresql', frontend: 'vue' } }
  let(:recipe) { Moduloproject::Recipe.load('8.1') }
  let(:generator) { described_class.new(name, options, recipe: recipe) }

  describe '#initialize' do
    it 'stores name, options, and recipe' do
      expect(generator.name).to eq(name)
      expect(generator.options).to eq(options)
      expect(generator.recipe).to eq(recipe)
    end
  end

  describe '#generate' do
    before do
      allow(generator).to receive(:system) do |cmd|
        @captured_command = cmd if cmd.include?('rails new')
        true
      end
      allow(generator).to receive(:puts)
    end

    it 'runs docker command' do
      generator.generate
      expect(@captured_command).to match(/docker run/)
    end

    it 'uses ruby version from options for docker image' do
      generator.generate
      expect(@captured_command).to match(/ruby:4/)
    end

    it 'includes rails new command' do
      generator.generate
      expect(@captured_command).to match(/rails new #{name}/)
    end

    context 'when docker command fails' do
      before do
        allow(generator).to receive(:system).and_return(false)
      end

      it 'raises an error' do
        expect { generator.generate }.to raise_error(RuntimeError, /Rails generation failed/)
      end
    end

    context 'with vue frontend' do
      it 'skips javascript (vite will be configured separately)' do
        generator.generate
        expect(@captured_command).to match(/--skip-javascript/)
      end

      it 'does not include css bootstrap option' do
        generator.generate
        expect(@captured_command).not_to match(/--css=bootstrap/)
      end
    end

    context 'with hotwire frontend' do
      let(:options) { { ruby: '4', rails: '8.1', database: 'postgresql', frontend: 'hotwire' } }

      it 'uses importmap javascript option' do
        generator.generate
        expect(@captured_command).to match(/--javascript=importmap/)
      end

      it 'includes css bootstrap option' do
        generator.generate
        expect(@captured_command).to match(/--css=bootstrap/)
      end
    end

    it 'always skips test and system test' do
      generator.generate
      expect(@captured_command).to match(/--skip-test/)
      expect(@captured_command).to match(/--skip-system-test/)
    end

    it 'always skips docker (we provide our own)' do
      generator.generate
      expect(@captured_command).to match(/--skip-docker/)
    end

    it 'uses database from options' do
      generator.generate
      expect(@captured_command).to match(/--database=postgresql/)
    end

    context 'database-specific Alpine packages' do
      it 'installs postgresql-dev and postgresql-client for postgresql' do
        generator.generate
        expect(@captured_command).to match(/postgresql-dev postgresql-client/)
      end

      context 'with mysql2 database' do
        let(:options) { { ruby: '4', rails: '8.1', database: 'mysql2', frontend: 'vue' } }

        it 'installs mariadb-dev and mariadb-client' do
          generator.generate
          expect(@captured_command).to match(/mariadb-dev mariadb-client/)
        end
      end

      context 'with sqlite3 database' do
        let(:options) { { ruby: '4', rails: '8.1', database: 'sqlite3', frontend: 'vue' } }

        it 'installs sqlite-dev' do
          generator.generate
          expect(@captured_command).to match(/sqlite-dev/)
        end
      end
    end

    it 'installs tzdata for timezone support in Alpine' do
      generator.generate
      expect(@captured_command).to match(/tzdata/)
    end

    it 'installs rails version from options' do
      generator.generate
      expect(@captured_command).to match(/gem install rails -v '~> 8\.1'/)
    end

    it 'includes --skip-solid with all non-solid backends' do
      generator.generate
      expect(@captured_command).to match(/--skip-solid/)
    end

    context 'with solid backend' do
      let(:options) { { ruby: '4', rails: '8.1', database: 'postgresql', frontend: 'vue', active_job: 'solid_queue' } }

      it 'does not include --skip-solid' do
        generator.generate
        expect(@captured_command).not_to match(/--skip-solid/)
      end
    end

    it 'fixes file ownership after generation' do
      chown_called = false
      allow(generator).to receive(:system) do |cmd|
        chown_called = true if cmd.include?('chown')
        true
      end
      generator.generate
      expect(chown_called).to be true
    end
  end
end
