# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/modulorails_setup'

RSpec.describe Moduloproject::ModulorailsSetup do
  let(:name) { 'test-app' }
  let(:options) { { ruby: '4', rails: '8.1' } }
  let(:setup) { described_class.new(name, options) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmpdir, name) }

  before do
    FileUtils.mkdir_p(File.join(project_dir, 'config', 'initializers'))
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
    context 'when Gemfile exists' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
      end

      it 'adds modulorails to Gemfile' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content).to include("gem 'modulorails'")
      end

      it 'includes comment about Modulotech' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content).to include('# Modulotech shared infrastructure')
      end

      it 'does not duplicate if already present' do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'modulorails'\n")
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content.scan('modulorails').count).to eq(1)
      end
    end

    context 'when Gemfile does not exist' do
      it 'does not raise error' do
        expect { setup.execute }.not_to raise_error
      end
    end

    context 'with modulorails 1.x' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
        File.write(File.join(project_dir, 'Gemfile.lock'), <<~LOCK)
          GEM
            specs:
              modulorails (1.5.0)
        LOCK
      end

      it 'creates initializer manually' do
        setup.execute
        initializer_path = File.join(project_dir, 'config', 'initializers', 'modulorails.rb')
        expect(File.exist?(initializer_path)).to be true
      end

      it 'does not call modulorails install' do
        expect(setup).not_to receive(:run_modulorails_install)
        setup.execute
      end

      it 'initializer contains proper configuration' do
        setup.execute
        content = File.read(File.join(project_dir, 'config', 'initializers', 'modulorails.rb'))

        expect(content).to include('Modulorails.configure')
        expect(content).to include("config.name 'TestApp'")
        expect(content).to include('config.main_developer')
        expect(content).to include('config.project_manager')
        expect(content).to include('config.endpoint')
        expect(content).to include('config.api_key')
      end
    end

    context 'with modulorails 2.x' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
        File.write(File.join(project_dir, 'Gemfile.lock'), <<~LOCK)
          GEM
            specs:
              modulorails (2.0.0)
        LOCK
      end

      it 'calls modulorails install via Docker' do
        expect(setup).to receive(:system).with(/modulorails install/).and_return(true)
        setup.execute
      end

      it 'does not create initializer manually' do
        allow(setup).to receive(:system).and_return(true)
        expect(setup).not_to receive(:create_initializer)
        setup.execute
      end
    end

    context 'when Gemfile.lock does not exist' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
      end

      it 'falls back to v1 behavior (creates initializer)' do
        setup.execute
        initializer_path = File.join(project_dir, 'config', 'initializers', 'modulorails.rb')
        expect(File.exist?(initializer_path)).to be true
      end
    end

    context 'when version cannot be parsed' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
        File.write(File.join(project_dir, 'Gemfile.lock'), 'invalid content')
      end

      it 'falls back to v1 behavior' do
        setup.execute
        initializer_path = File.join(project_dir, 'config', 'initializers', 'modulorails.rb')
        expect(File.exist?(initializer_path)).to be true
      end
    end

    context 'when modulorails install fails' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
        File.write(File.join(project_dir, 'Gemfile.lock'), <<~LOCK)
          GEM
            specs:
              modulorails (2.0.0)
        LOCK
        allow(setup).to receive(:system).with(/bundle install/).and_return(true)
        allow(setup).to receive(:system).with(/modulorails install/).and_return(false)
      end

      it 'raises an error' do
        expect { setup.execute }.to raise_error('Modulorails install failed')
      end
    end

    context 'with hyphenated project name' do
      let(:name) { 'my-cool-app' }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, name, 'config', 'initializers'))
        File.write(File.join(tmpdir, name, 'Gemfile'), '')
        File.write(File.join(tmpdir, name, 'Gemfile.lock'), <<~LOCK)
          GEM
            specs:
              modulorails (1.5.0)
        LOCK
      end

      it 'camelizes name in initializer' do
        setup.execute
        content = File.read(File.join(tmpdir, name, 'config', 'initializers', 'modulorails.rb'))
        expect(content).to include("config.name 'MyCoolApp'")
      end
    end

    context 'with underscored project name' do
      let(:name) { 'my_cool_app' }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, name, 'config', 'initializers'))
        File.write(File.join(tmpdir, name, 'Gemfile'), '')
        File.write(File.join(tmpdir, name, 'Gemfile.lock'), <<~LOCK)
          GEM
            specs:
              modulorails (1.5.0)
        LOCK
      end

      it 'camelizes name in initializer' do
        setup.execute
        content = File.read(File.join(tmpdir, name, 'config', 'initializers', 'modulorails.rb'))
        expect(content).to include("config.name 'MyCoolApp'")
      end
    end
  end

  describe '#detect_version' do
    before do
      File.write(File.join(project_dir, 'Gemfile'), '')
    end

    it 'detects version from Gemfile.lock' do
      File.write(File.join(project_dir, 'Gemfile.lock'), <<~LOCK)
        GEM
          specs:
            modulorails (1.5.0)
      LOCK
      expect(setup.send(:detect_version)).to eq('1.5.0')
    end

    it 'detects two-part version' do
      File.write(File.join(project_dir, 'Gemfile.lock'), <<~LOCK)
        GEM
          specs:
            modulorails (2.0)
      LOCK
      expect(setup.send(:detect_version)).to eq('2.0')
    end

    it 'returns nil when Gemfile.lock does not exist' do
      expect(setup.send(:detect_version)).to be_nil
    end

    it 'returns nil when version cannot be parsed' do
      File.write(File.join(project_dir, 'Gemfile.lock'), 'invalid content')
      expect(setup.send(:detect_version)).to be_nil
    end
  end

  describe '#version_1?' do
    it 'returns true for nil version' do
      expect(setup.send(:version_1?, nil)).to be true
    end

    it 'returns true for version 1.x' do
      expect(setup.send(:version_1?, '1.5.0')).to be true
      expect(setup.send(:version_1?, '1.0.0')).to be true
      expect(setup.send(:version_1?, '1.9.9')).to be true
    end

    it 'returns false for version 2.x' do
      expect(setup.send(:version_1?, '2.0.0')).to be false
      expect(setup.send(:version_1?, '2.1.0')).to be false
    end

    it 'returns false for version 3.x and higher' do
      expect(setup.send(:version_1?, '3.0.0')).to be false
      expect(setup.send(:version_1?, '10.0.0')).to be false
    end

    it 'returns true for version 0.x' do
      expect(setup.send(:version_1?, '0.9.0')).to be true
    end
  end

  describe '#docker_image' do
    it 'returns ruby alpine image with correct version' do
      expect(setup.send(:docker_image)).to eq('ruby:4-alpine')
    end

    context 'with different ruby version' do
      let(:options) { { ruby: '3.3', rails: '8.0' } }

      it 'uses the specified ruby version' do
        expect(setup.send(:docker_image)).to eq('ruby:3.3-alpine')
      end
    end
  end

  describe '#build_modulorails_docker_command' do
    it 'builds correct docker command' do
      command = setup.send(:build_modulorails_docker_command)
      expect(command).to include('docker run --rm')
      expect(command).to include("#{name}:/app\"")
      expect(command).to include('-w /app')
      expect(command).to include('-e HOME=/tmp')
      expect(command).to include('ruby:4-alpine')
      expect(command).to include('bundle exec modulorails install')
    end
  end

  describe '#current_uid_gid' do
    it 'returns uid:gid format' do
      result = setup.send(:current_uid_gid)
      expect(result).to match(/^\d+:\d+$/)
    end

    it 'memoizes the result' do
      first_call = setup.send(:current_uid_gid)
      second_call = setup.send(:current_uid_gid)
      expect(first_call).to eq(second_call)
    end
  end

  describe '#fix_file_ownership' do
    it 'runs docker chown command' do
      uid_gid = setup.send(:current_uid_gid)
      expect(setup).to receive(:system).with(%r{chown -R #{uid_gid} /app})
      setup.send(:fix_file_ownership)
    end
  end
end
