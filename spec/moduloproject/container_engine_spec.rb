# frozen_string_literal: true

require 'spec_helper'
require 'moduloproject/container_engine'

RSpec.describe Moduloproject::ContainerEngine do
  around do |example|
    saved = ENV.fetch('CONTAINER_ENGINE', nil)
    ENV.delete('CONTAINER_ENGINE')
    described_class.reset!
    example.run
  ensure
    saved.nil? ? ENV.delete('CONTAINER_ENGINE') : ENV['CONTAINER_ENGINE'] = saved
    described_class.reset!
  end

  def stub_engines(docker:, podman:)
    allow(described_class).to receive(:system)
      .with('docker info', out: File::NULL, err: File::NULL).and_return(docker)
    allow(described_class).to receive(:system)
      .with('podman --version', out: File::NULL, err: File::NULL).and_return(podman)
  end

  describe '.command' do
    it 'honours CONTAINER_ENGINE' do
      ENV['CONTAINER_ENGINE'] = 'podman'
      expect(described_class.command).to eq('podman')
    end

    it 'uses docker when its daemon answers' do
      stub_engines(docker: true, podman: true)
      expect(described_class.command).to eq('docker')
    end

    it 'falls back to podman when the docker daemon does not answer' do
      stub_engines(docker: false, podman: true)
      expect(described_class.command).to eq('podman')
    end

    it 'defaults to docker when neither engine is usable' do
      stub_engines(docker: nil, podman: nil)
      expect(described_class.command).to eq('docker')
    end

    it 'detects the engine once' do
      stub_engines(docker: true, podman: true)
      2.times { described_class.command }
      expect(described_class).to have_received(:system).once
    end
  end

  describe '.rootless_podman?' do
    it 'is false for docker' do
      ENV['CONTAINER_ENGINE'] = 'docker'
      expect(described_class.rootless_podman?).to be false
    end

    it 'is true for rootless podman' do
      ENV['CONTAINER_ENGINE'] = 'podman'
      allow(described_class).to receive(:`)
        .with('podman info --format {{.Host.Security.Rootless}} 2>/dev/null').and_return("true\n")
      expect(described_class.rootless_podman?).to be true
    end

    it 'is false for rootful podman' do
      ENV['CONTAINER_ENGINE'] = 'podman'
      allow(described_class).to receive(:`)
        .with('podman info --format {{.Host.Security.Rootless}} 2>/dev/null').and_return("false\n")
      expect(described_class.rootless_podman?).to be false
    end
  end

  describe '.image' do
    it 'qualifies an official image' do
      expect(described_class.image('ruby:4-alpine')).to eq('docker.io/library/ruby:4-alpine')
    end

    it 'qualifies a namespaced Docker Hub image' do
      expect(described_class.image('modulotechgroup/fast:dev')).to eq('docker.io/modulotechgroup/fast:dev')
    end

    it 'keeps an image that names its registry' do
      expect(described_class.image('ghcr.io/org/app:1')).to eq('ghcr.io/org/app:1')
    end
  end
end
