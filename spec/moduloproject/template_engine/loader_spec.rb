# frozen_string_literal: true

RSpec.describe Moduloproject::TemplateEngine::Loader do
  let(:templates_root) { Moduloproject::TemplateEngine.templates_root }
  subject { described_class.new(templates_root) }

  describe '#load' do
    it 'loads template from rails-8.1' do
      content = subject.load('docker/Dockerfile.prod.erb', '8.1.0')
      expect(content).to include('FROM docker.io/library/ruby')
    end

    it 'resolves template through inheritance chain' do
      # rails-7.1 inherits from rails-8.0 which inherits from rails-8.1
      # Template should be found in rails-8.1
      content = subject.load('docker/Dockerfile.prod.erb', '7.1.0')
      expect(content).to include('FROM docker.io/library/ruby')
    end

    it 'raises TemplateNotFoundError for missing template' do
      expect { subject.load('nonexistent/template.erb', '8.1.0') }
        .to raise_error(Moduloproject::TemplateEngine::Loader::TemplateNotFoundError, /Template not found/)
    end
  end

  describe '#load_partial' do
    it 'loads partial from shared/partials/' do
      content = subject.load_partial('ruby_install')
      expect(content).to include('apk add')
    end

    it 'raises TemplateNotFoundError for missing partial' do
      expect { subject.load_partial('nonexistent') }
        .to raise_error(Moduloproject::TemplateEngine::Loader::TemplateNotFoundError, /Partial not found/)
    end
  end

  describe '#resolve_path' do
    it 'resolves template path in version directory' do
      path = subject.resolve_path('docker/Dockerfile.prod.erb', '8.1.0')
      expect(path).to end_with('rails-8.1/docker/Dockerfile.prod.erb')
      expect(File.exist?(path)).to be true
    end

    it 'resolves through inheritance chain' do
      path = subject.resolve_path('docker/Dockerfile.prod.erb', '7.1.0')
      expect(path).to end_with('rails-8.1/docker/Dockerfile.prod.erb')
    end

    it 'returns nil for non-existent template' do
      path = subject.resolve_path('nonexistent/template.erb', '8.1.0')
      expect(path).to be_nil
    end

    context 'fallback to shared directory' do
      let(:temp_root) { Dir.mktmpdir }
      let(:temp_loader) { described_class.new(temp_root) }

      after { FileUtils.rm_rf(temp_root) }

      it 'resolves template from shared/ when not in version directories' do
        # Create shared template only (not in any version directory)
        FileUtils.mkdir_p(File.join(temp_root, 'shared', 'common'))
        FileUtils.mkdir_p(File.join(temp_root, 'rails-8.1'))
        File.write(File.join(temp_root, 'shared', 'common', 'shared_template.erb'), 'shared content')
        File.write(File.join(temp_root, 'rails-8.1', 'manifest.yml'), '')

        path = temp_loader.resolve_path('common/shared_template.erb', '8.1.0')
        expect(path).to end_with('shared/common/shared_template.erb')
        expect(File.exist?(path)).to be true
      end
    end
  end

  describe '#resolve_static_path' do
    it 'resolves static file path' do
      path = subject.resolve_static_path('docker/Dockerfile.prod.erb', '8.1.0')
      expect(path).to end_with('rails-8.1/docker/Dockerfile.prod.erb')
    end
  end

  describe '#normalize_version' do
    it 'converts version string to directory name' do
      expect(subject.normalize_version('8.1.0')).to eq('rails-8.1')
      expect(subject.normalize_version('8.0.2')).to eq('rails-8.0')
      expect(subject.normalize_version('7.1.3')).to eq('rails-7.1')
    end

    it 'preserves already normalized versions' do
      expect(subject.normalize_version('rails-8.1')).to eq('rails-8.1')
      expect(subject.normalize_version('rails-7.1')).to eq('rails-7.1')
    end

    it 'defaults to rails-8.1 for invalid versions' do
      expect(subject.normalize_version('')).to eq('rails-8.1')
      expect(subject.normalize_version(nil)).to eq('rails-8.1')
    end
  end

  describe '#inheritance_chain_for' do
    it 'returns inheritance chain for version' do
      chain = subject.inheritance_chain_for('7.1.0')
      expect(chain.versions).to eq(%w[rails-7.1 rails-8.0 rails-8.1])
    end

    it 'caches inheritance chains' do
      chain1 = subject.inheritance_chain_for('7.1.0')
      chain2 = subject.inheritance_chain_for('7.1.0')
      expect(chain1).to be(chain2)
    end
  end

  describe '#default_version' do
    it 'returns rails-8.1' do
      expect(subject.default_version).to eq('rails-8.1')
    end
  end
end
