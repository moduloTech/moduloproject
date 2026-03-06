# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Moduloproject::Setup::BrakemanSetup do
  let(:tmpdir) { Dir.mktmpdir }
  let(:name) { 'test-app' }
  let(:project_dir) { File.join(tmpdir, name) }
  let(:options) { { ruby: '4' } }
  let(:setup) { described_class.new(project_dir, options) }

  before do
    FileUtils.mkdir_p(project_dir)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#execute' do
    context 'when Gemfile exists' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rails'\n")
      end

      it 'adds brakeman to Gemfile' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content).to include("gem 'brakeman', require: false, group: :development")
      end

      it 'adds security comment' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content).to include('# Security analysis')
      end

      it 'does not add brakeman twice' do
        setup.execute
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content.scan('brakeman').count).to eq(1)
      end
    end

    context 'when Gemfile does not exist' do
      it 'does not raise' do
        expect { setup.execute }.not_to raise_error
      end
    end

    context 'when brakeman is already in Gemfile' do
      before do
        File.write(File.join(project_dir, 'Gemfile'), "gem 'brakeman'\n")
      end

      it 'does not add it again' do
        setup.execute
        content = File.read(File.join(project_dir, 'Gemfile'))
        expect(content.scan('brakeman').count).to eq(1)
      end
    end
  end
end
