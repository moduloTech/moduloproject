# frozen_string_literal: true

RSpec.describe Moduloproject::TemplateEngine::InheritanceChain do
  let(:templates_root) { Moduloproject::TemplateEngine.templates_root }

  describe '#initialize' do
    context 'with rails-7.1' do
      subject { described_class.new('rails-7.1', templates_root) }

      it 'builds the full inheritance chain' do
        expect(subject.versions).to eq(%w[rails-7.1 rails-8.0 rails-8.1])
      end

      it 'includes all versions in the chain' do
        expect(subject.include?('rails-7.1')).to be true
        expect(subject.include?('rails-8.0')).to be true
        expect(subject.include?('rails-8.1')).to be true
      end
    end

    context 'with rails-8.0' do
      subject { described_class.new('rails-8.0', templates_root) }

      it 'builds chain up to reference' do
        expect(subject.versions).to eq(%w[rails-8.0 rails-8.1])
      end
    end

    context 'with rails-8.1 (reference)' do
      subject { described_class.new('rails-8.1', templates_root) }

      it 'has only itself in the chain' do
        expect(subject.versions).to eq(['rails-8.1'])
      end
    end

    context 'with non-existent version' do
      subject { described_class.new('rails-99.0', templates_root) }

      it 'has only itself in the chain' do
        expect(subject.versions).to eq(['rails-99.0'])
      end
    end
  end

  describe '#merged_variables' do
    context 'with rails-7.1' do
      subject { described_class.new('rails-7.1', templates_root) }

      it 'merges variables from all manifests' do
        vars = subject.merged_variables
        expect(vars['default_ruby_version']).to eq('3.3.0')
      end

      it 'child variables override parent variables' do
        vars = subject.merged_variables
        # rails-7.1 overrides use_propshaft to false
        expect(vars['use_propshaft']).to be false
      end
    end

    context 'with rails-8.1' do
      subject { described_class.new('rails-8.1', templates_root) }

      it 'returns only reference variables' do
        vars = subject.merged_variables
        expect(vars['use_propshaft']).to be true
      end
    end

    context 'with version without manifest' do
      let(:temp_root) { Dir.mktmpdir }

      after { FileUtils.rm_rf(temp_root) }

      it 'skips versions without manifest when merging' do
        # Create a chain: rails-child -> rails-parent (no manifest)
        FileUtils.mkdir_p(File.join(temp_root, 'rails-child'))
        FileUtils.mkdir_p(File.join(temp_root, 'rails-parent'))

        File.write(
          File.join(temp_root, 'rails-child', 'manifest.yml'),
          "inherits_from: rails-parent\nvariables:\n  child_var: true"
        )
        # rails-parent has no manifest.yml

        chain = described_class.new('rails-child', temp_root)
        vars = chain.merged_variables

        expect(vars['child_var']).to be true
        expect(vars.keys).to eq(['child_var'])
      end
    end
  end

  describe '#manifest_for' do
    subject { described_class.new('rails-8.1', templates_root) }

    it 'returns manifest for existing version' do
      manifest = subject.manifest_for('rails-8.1')
      expect(manifest).to be_a(Moduloproject::TemplateEngine::Manifest)
      expect(manifest.version).to eq('rails-8.1')
    end

    it 'returns nil for non-existent version' do
      manifest = subject.manifest_for('rails-99.0')
      expect(manifest).to be_nil
    end

    it 'caches manifests' do
      manifest1 = subject.manifest_for('rails-8.1')
      manifest2 = subject.manifest_for('rails-8.1')
      expect(manifest1).to be(manifest2)
    end
  end

  describe 'circular inheritance protection' do
    it 'raises CircularInheritanceError for circular references' do
      temp_root = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(temp_root, 'rails-a'))
      FileUtils.mkdir_p(File.join(temp_root, 'rails-b'))

      File.write(
        File.join(temp_root, 'rails-a', 'manifest.yml'),
        "inherits_from: rails-b"
      )
      File.write(
        File.join(temp_root, 'rails-b', 'manifest.yml'),
        "inherits_from: rails-a"
      )

      expect { described_class.new('rails-a', temp_root) }
        .to raise_error(Moduloproject::TemplateEngine::InheritanceChain::CircularInheritanceError)

      FileUtils.rm_rf(temp_root)
    end
  end
end
