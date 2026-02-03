# frozen_string_literal: true

RSpec.describe Moduloproject::Generators::Base do
  let(:project_root) { Dir.mktmpdir }
  let(:context) { Moduloproject::Context.new(project_root: project_root) }

  after do
    FileUtils.rm_rf(project_root)
  end

  describe '#initialize' do
    it 'accepts context and options' do
      generator = described_class.new(context, force: true)
      expect(generator.context).to eq(context)
      expect(generator.options).to eq(force: true)
    end
  end

  describe '#generate' do
    it 'raises NotImplementedError' do
      generator = described_class.new(context)
      expect { generator.generate }.to raise_error(NotImplementedError)
    end
  end

  describe '#generator_name' do
    it 'returns snake_case class name' do
      generator = described_class.new(context)
      expect(generator.generator_name).to eq('base')
    end
  end

  describe '#version' do
    it 'returns the VERSION constant' do
      generator = described_class.new(context)
      expect(generator.version).to eq(1)
    end

    it 'returns 1 when VERSION constant is not defined' do
      generator = described_class.new(context)
      allow(generator.class).to receive(:const_get).with(:VERSION).and_raise(NameError)
      expect(generator.version).to eq(1)
    end
  end

  describe 'protected methods' do
    let(:generator) { described_class.new(context) }

    describe '#write_file' do
      it 'creates a new file' do
        generator.send(:write_file, 'test.txt', 'hello world')
        expect(File.read(File.join(project_root, 'test.txt'))).to eq('hello world')
      end

      it 'creates parent directories' do
        generator.send(:write_file, 'a/b/c/test.txt', 'hello')
        expect(File.exist?(File.join(project_root, 'a/b/c/test.txt'))).to be true
      end

      it 'does not overwrite without force option' do
        File.write(File.join(project_root, 'existing.txt'), 'original')
        generator.send(:write_file, 'existing.txt', 'new content')
        expect(File.read(File.join(project_root, 'existing.txt'))).to eq('original')
      end

      it 'overwrites with force option' do
        File.write(File.join(project_root, 'existing.txt'), 'original')
        generator.send(:write_file, 'existing.txt', 'new content', force: true)
        expect(File.read(File.join(project_root, 'existing.txt'))).to eq('new content')
      end

      it 'sets executable permission when requested' do
        generator.send(:write_file, 'script.sh', '#!/bin/sh', executable: true)
        file_path = File.join(project_root, 'script.sh')
        expect(File.executable?(file_path)).to be true
      end
    end

    describe '#file_exists?' do
      it 'returns true for existing file' do
        File.write(File.join(project_root, 'exists.txt'), 'content')
        expect(generator.send(:file_exists?, 'exists.txt')).to be true
      end

      it 'returns false for non-existing file' do
        expect(generator.send(:file_exists?, 'missing.txt')).to be false
      end
    end

    describe '#delete_file' do
      it 'removes existing file' do
        path = File.join(project_root, 'to_remove.txt')
        File.write(path, 'content')
        generator.send(:delete_file, 'to_remove.txt')
        expect(File.exist?(path)).to be false
      end

      it 'does nothing for non-existing file' do
        expect { generator.send(:delete_file, 'missing.txt') }.not_to raise_error
      end
    end

    describe '#project_root' do
      it 'returns context project root' do
        expect(generator.send(:project_root)).to eq(project_root)
      end
    end

    describe '#log_action' do
      it 'does nothing when verbose is false' do
        allow(generator).to receive(:puts)
        generator.send(:log_action, 'create', 'test.txt')
        expect(generator).not_to have_received(:puts)
      end

      context 'when verbose is true' do
        let(:verbose_generator) { described_class.new(context, verbose: true) }

        it 'calls puts with formatted output' do
          allow(verbose_generator).to receive(:puts).and_return('output')
          result = verbose_generator.send(:log_action, 'create', 'test.txt')
          expect(verbose_generator).to have_received(:puts).with('  create       test.txt')
          expect(result).to eq('output')
        end
      end
    end

    describe '#copy_file' do
      let(:templates_root) { Moduloproject::TemplateEngine.templates_root }
      let(:source_path) { 'docker/dockerignore.erb' }

      it 'copies a file from templates to project' do
        generator.send(:copy_file, source_path, '.dockerignore')
        target_path = File.join(project_root, '.dockerignore')
        expect(File.exist?(target_path)).to be true
      end

      it 'preserves file content' do
        generator.send(:copy_file, source_path, '.dockerignore')
        target_path = File.join(project_root, '.dockerignore')
        source_full_path = File.join(templates_root, 'rails-8.1', source_path)
        expect(File.read(target_path)).to eq(File.read(source_full_path))
      end
    end

    describe 'keepfile methods' do
      describe '#read_keepfile' do
        it 'returns empty hash when no keepfile exists' do
          expect(generator.send(:read_keepfile)).to eq({})
        end

        it 'reads existing keepfile' do
          keepfile_path = File.join(project_root, '.moduloproject.yml')
          File.write(keepfile_path, { 'docker' => { 'version' => 2 } }.to_yaml)
          expect(generator.send(:read_keepfile)).to eq({ 'docker' => { 'version' => 2 } })
        end
      end

      describe '#skip_generation?' do
        it 'returns false when no keepfile exists' do
          expect(generator.send(:skip_generation?)).to be false
        end

        it 'returns false when force option is set' do
          generator_with_force = described_class.new(context, force: true)
          expect(generator_with_force.send(:skip_generation?)).to be false
        end

        it 'returns true when version is already satisfied' do
          keepfile_path = File.join(project_root, '.moduloproject.yml')
          File.write(keepfile_path, { 'base' => { 'version' => 1 } }.to_yaml)
          expect(generator.send(:skip_generation?)).to be true
        end
      end
    end
  end
end
