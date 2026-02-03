# frozen_string_literal: true

RSpec.describe Moduloproject::TemplateEngine::Manifest do
  let(:templates_root) { Moduloproject::TemplateEngine.templates_root }

  describe '#initialize' do
    context 'with rails-8.1 (reference version)' do
      subject { described_class.new('rails-8.1', templates_root) }

      it 'loads the manifest file' do
        expect(subject.exists?).to be true
      end

      it 'has no inherits_from (reference version)' do
        expect(subject.inherits_from).to be_nil
      end

      it 'is a reference version' do
        expect(subject.reference?).to be true
      end

      it 'loads variables' do
        expect(subject.variables).to be_a(Hash)
        expect(subject.variables['default_ruby_version']).to eq('3.3.0')
      end
    end

    context 'with rails-8.0 (inherits from 8.1)' do
      subject { described_class.new('rails-8.0', templates_root) }

      it 'loads the manifest file' do
        expect(subject.exists?).to be true
      end

      it 'inherits from rails-8.1' do
        expect(subject.inherits_from).to eq('rails-8.1')
      end

      it 'is not a reference version' do
        expect(subject.reference?).to be false
      end
    end

    context 'with rails-7.1 (inherits from 8.0)' do
      subject { described_class.new('rails-7.1', templates_root) }

      it 'inherits from rails-8.0' do
        expect(subject.inherits_from).to eq('rails-8.0')
      end

      it 'can override variables' do
        expect(subject.variables['use_propshaft']).to be false
      end
    end

    context 'with non-existent version' do
      subject { described_class.new('rails-99.0', templates_root) }

      it 'does not exist' do
        expect(subject.exists?).to be false
      end

      it 'has no inherits_from' do
        expect(subject.inherits_from).to be_nil
      end

      it 'has empty variables' do
        expect(subject.variables).to eq({})
      end
    end

    context 'with empty manifest file' do
      let(:temp_root) { Dir.mktmpdir }

      after { FileUtils.rm_rf(temp_root) }

      it 'handles nil content gracefully' do
        FileUtils.mkdir_p(File.join(temp_root, 'rails-empty'))
        File.write(File.join(temp_root, 'rails-empty', 'manifest.yml'), '')

        manifest = described_class.new('rails-empty', temp_root)
        expect(manifest.exists?).to be true
        expect(manifest.inherits_from).to be_nil
        expect(manifest.variables).to eq({})
        expect(manifest.overrides).to eq([])
      end
    end
  end

  describe '#override?' do
    let(:manifest_with_overrides) do
      # Create a temporary manifest with overrides
      temp_root = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(temp_root, 'rails-test'))
      File.write(
        File.join(temp_root, 'rails-test', 'manifest.yml'),
        <<~YAML
          inherits_from: rails-8.1
          overrides:
            - docker/Dockerfile.prod.erb
            - ci/.gitlab-ci.yml.erb
        YAML
      )
      [described_class.new('rails-test', temp_root), temp_root]
    end

    after do
      FileUtils.rm_rf(manifest_with_overrides[1])
    end

    it 'returns true for overridden templates' do
      manifest, = manifest_with_overrides
      expect(manifest.override?('docker/Dockerfile.prod.erb')).to be true
    end

    it 'returns false for non-overridden templates' do
      manifest, = manifest_with_overrides
      expect(manifest.override?('config/database.yml.erb')).to be false
    end
  end

  describe 'error handling' do
    it 'raises ParseError for invalid YAML' do
      temp_root = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(temp_root, 'rails-broken'))
      File.write(
        File.join(temp_root, 'rails-broken', 'manifest.yml'),
        "invalid: yaml: content: {"
      )

      expect { described_class.new('rails-broken', temp_root) }
        .to raise_error(Moduloproject::TemplateEngine::Manifest::ParseError, /Invalid YAML/)

      FileUtils.rm_rf(temp_root)
    end

    it 'raises ParseError for non-hash manifest' do
      temp_root = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(temp_root, 'rails-array'))
      File.write(
        File.join(temp_root, 'rails-array', 'manifest.yml'),
        "- item1\n- item2"
      )

      expect { described_class.new('rails-array', temp_root) }
        .to raise_error(Moduloproject::TemplateEngine::Manifest::ParseError, /must be a hash/)

      FileUtils.rm_rf(temp_root)
    end
  end
end
