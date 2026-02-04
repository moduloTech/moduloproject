# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/vite_setup'

RSpec.describe Moduloproject::ViteSetup do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1', frontend: 'vue' } }
  let(:setup) { described_class.new(name, options) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmpdir, name) }

  before do
    FileUtils.mkdir_p(project_dir)
    Dir.chdir(tmpdir)
    allow(setup).to receive(:puts)
    allow(setup).to receive(:system).and_return(true)
  end

  after do
    Dir.chdir('/')
    FileUtils.rm_rf(tmpdir)
  end

  describe '#initialize' do
    it 'stores name and options' do
      expect(setup.name).to eq(name)
      expect(setup.options).to eq(options)
    end
  end

  describe '#execute' do
    context 'with vue frontend' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
      end

      it 'adds vite_rails to Gemfile' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content).to include("gem 'vite_rails'")
      end

      it 'includes comment about Vite' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content).to include('# Vite for modern JavaScript bundling')
      end

      it 'does not duplicate if already present' do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'vite_rails'\n")
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content.scan('vite_rails').count).to eq(1)
      end

      it 'runs vite install via docker' do
        expect(setup).to receive(:system).with(/docker run.*bundle exec vite install/).and_return(true)
        setup.execute
      end

      it 'generates Bundler binstub for vite_ruby' do
        expect(setup).to receive(:system).with(/bundle binstubs vite_ruby --force/).and_return(true)
        setup.execute
      end

      it 'installs Vue dependencies via npm' do
        expect(setup).to receive(:system).with(%r{npm install @vueuse/core vue vue-i18n vue-multiselect vue-router}).and_return(true)
        setup.execute
      end

      it 'installs Vue devDependencies via npm' do
        expect(setup).to receive(:system).with(%r{npm install -D @vitejs/plugin-vue.*vitest}).and_return(true)
        setup.execute
      end

      it 'uses ruby version from options for docker image' do
        expect(setup).to receive(:system).with(/ruby:4/).and_return(true)
        setup.execute
      end

      it 'includes database packages in docker command for postgresql' do
        opts = { ruby: '4', rails: '8.1', frontend: 'vue', database: 'postgresql' }
        pg_setup = described_class.new(name, opts)
        allow(pg_setup).to receive(:puts)
        allow(pg_setup).to receive(:system).and_return(true)
        expect(pg_setup).to receive(:system).with(/postgresql-dev postgresql-client/).and_return(true)
        pg_setup.execute
      end

      it 'includes database packages in docker command for mysql2' do
        opts = { ruby: '4', rails: '8.1', frontend: 'vue', database: 'mysql2' }
        mysql_setup = described_class.new(name, opts)
        allow(mysql_setup).to receive(:puts)
        allow(mysql_setup).to receive(:system).and_return(true)
        expect(mysql_setup).to receive(:system).with(/mariadb-dev mariadb-client/).and_return(true)
        mysql_setup.execute
      end

      it 'includes database packages in docker command for sqlite3' do
        opts = { ruby: '4', rails: '8.1', frontend: 'vue', database: 'sqlite3' }
        sqlite_setup = described_class.new(name, opts)
        allow(sqlite_setup).to receive(:puts)
        allow(sqlite_setup).to receive(:system).and_return(true)
        expect(sqlite_setup).to receive(:system).with(/sqlite-dev/).and_return(true)
        sqlite_setup.execute
      end

      it 'fixes file ownership after installation' do
        chown_called = false
        allow(setup).to receive(:system) do |cmd|
          chown_called = true if cmd.include?('chown')
          true
        end
        setup.execute
        expect(chown_called).to be true
      end

      context 'when docker command fails' do
        before do
          allow(setup).to receive(:system).and_return(false)
        end

        it 'raises an error' do
          expect { setup.execute }.to raise_error(RuntimeError, /Vite installation failed/)
        end
      end
    end

    context 'with hotwire frontend' do
      let(:options) { { ruby: '4', rails: '8.1', frontend: 'hotwire' } }

      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
      end

      it 'does not modify Gemfile' do
        original_content = File.read(File.join(project_dir, 'Gemfile'))
        setup.execute
        expect(File.read(File.join(project_dir, 'Gemfile'))).to eq(original_content)
      end

      it 'does not run docker command' do
        expect(setup).not_to receive(:system)
        setup.execute
      end
    end

    context 'when Gemfile does not exist' do
      let(:options) { { ruby: '4', rails: '8.1', frontend: 'vue' } }

      it 'still runs vite install' do
        expect(setup).to receive(:system).with(/vite install/).and_return(true)
        setup.execute
      end
    end

    context 'package.json scripts' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
        File.write(File.join(project_dir, 'package.json'), '{"dependencies":{}}')
      end

      it 'adds vue scripts to package.json' do
        setup.execute
        pkg = JSON.parse(File.read(File.join(project_dir, 'package.json')))
        expect(pkg['scripts']['build']).to eq('bin/vite build')
        expect(pkg['scripts']['dev']).to eq('bin/vite')
        expect(pkg['scripts']['lint']).to eq('npx eslint app/frontend')
        expect(pkg['scripts']['test']).to eq('vitest run')
        expect(pkg['scripts']['test:watch']).to eq('vitest')
        expect(pkg['scripts']['test:coverage']).to eq('vitest run --coverage')
      end

      it 'preserves existing scripts' do
        File.write(File.join(project_dir, 'package.json'), '{"scripts":{"existing":"keep"}}')
        setup.execute
        pkg = JSON.parse(File.read(File.join(project_dir, 'package.json')))
        expect(pkg['scripts']['existing']).to eq('keep')
        expect(pkg['scripts']['build']).to eq('bin/vite build')
      end

      it 'does not modify package.json when missing' do
        FileUtils.rm_f(File.join(project_dir, 'package.json'))
        expect { setup.execute }.not_to raise_error
      end
    end

    context 'bin/vite creation' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
      end

      it 'creates bin/vite when missing' do
        setup.execute
        bin_vite = File.join(project_dir, 'bin/vite')
        expect(File.exist?(bin_vite)).to be true
        expect(File.read(bin_vite)).to include('vite_ruby')
        expect(File.executable?(bin_vite)).to be true
      end

      it 'does not overwrite existing bin/vite' do
        FileUtils.mkdir_p(File.join(project_dir, 'bin'))
        File.write(File.join(project_dir, 'bin/vite'), 'existing content')
        setup.execute
        expect(File.read(File.join(project_dir, 'bin/vite'))).to eq('existing content')
      end
    end

    context 'bin/dev foreman setup' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'rails'\n")
        FileUtils.mkdir_p(File.join(project_dir, 'bin'))
      end

      it 'rewrites bin/dev to use foreman when it does not contain foreman' do
        File.write(File.join(project_dir, 'bin/dev'), "#!/usr/bin/env ruby\nexec \"./bin/rails\", \"server\"\n")
        setup.execute
        content = File.read(File.join(project_dir, 'bin/dev'))
        expect(content).to include('foreman')
        expect(content).to include('Procfile.dev')
        expect(File.executable?(File.join(project_dir, 'bin/dev'))).to be true
      end

      it 'does not overwrite bin/dev if it already references foreman' do
        original = "#!/bin/sh\nexec foreman start -f Procfile.dev\n"
        File.write(File.join(project_dir, 'bin/dev'), original)
        setup.execute
        expect(File.read(File.join(project_dir, 'bin/dev'))).to eq(original)
      end

      it 'creates bin/dev when missing' do
        setup.execute
        bin_dev = File.join(project_dir, 'bin/dev')
        expect(File.exist?(bin_dev)).to be true
        expect(File.read(bin_dev)).to include('foreman')
      end
    end
  end
end
