# frozen_string_literal: true

RSpec.describe Moduloproject::TemplateEngine do
  let(:context) do
    Moduloproject::Context.new(
      project_root: '/tmp/test',
      project_name: 'test-app',
      ruby_version: '3.3.0',
      rails_version: '8.1.0'
    )
  end

  after do
    described_class.reset!
  end

  describe '.load' do
    it 'loads and renders a template' do
      content = described_class.load('docker/dockerignore.erb', context)
      expect(content).to be_a(String)
      expect(content).to include('.moduloproject.yml')
    end

    it 'raises TemplateNotFoundError for missing template' do
      expect { described_class.load('nonexistent/template.erb', context) }
        .to raise_error(Moduloproject::TemplateEngine::TemplateNotFoundError, /Template not found/)
    end

    context 'with version inheritance' do
      let(:context_71) do
        Moduloproject::Context.new(
          project_root: '/tmp/test',
          project_name: 'test-app',
          ruby_version: '3.3.0',
          rails_version: '7.2.0'
        )
      end

      let(:context_80) do
        Moduloproject::Context.new(
          project_root: '/tmp/test',
          project_name: 'test-app',
          ruby_version: '3.3.0',
          rails_version: '8.0.0'
        )
      end

      it 'loads template for Rails 7.2 through inheritance chain' do
        content = described_class.load('docker/Dockerfile.prod.erb', context_71)
        expect(content).to include('FROM docker.io/library/ruby')
      end

      it 'loads template for Rails 8.0 through inheritance chain' do
        content = described_class.load('docker/Dockerfile.prod.erb', context_80)
        expect(content).to include('FROM docker.io/library/ruby')
      end
    end
  end

  describe '.render' do
    it 'renders ERB content with context' do
      template = '<%= project_name %> uses Ruby <%= ruby_version %>'
      result = described_class.render(template, context)
      expect(result).to eq('test-app uses Ruby 3.3.0')
    end

    it 'provides helper methods' do
      template = 'PostgreSQL: <%= postgresql? %>, MySQL: <%= mysql? %>'
      result = described_class.render(template, context)
      expect(result).to eq('PostgreSQL: true, MySQL: false')
    end

    it 'provides rails_version_gte? helper' do
      template = 'Rails 7.2+: <%= rails_version_gte?("7.2") %>'
      result = described_class.render(template, context)
      expect(result).to eq('Rails 7.2+: true')
    end
  end

  describe '.templates_root' do
    it 'returns the templates directory path' do
      expect(described_class.templates_root).to end_with('templates')
      expect(Dir.exist?(described_class.templates_root)).to be true
    end
  end

  describe '.default_version' do
    it 'returns rails-8.1' do
      expect(described_class.default_version).to eq('rails-8.1')
    end
  end

  describe '.resolve_static_path' do
    it 'resolves static file path for rails-8.1' do
      path = described_class.resolve_static_path('docker/Dockerfile.prod.erb', '8.1.0')
      expect(path).to end_with('rails-8.1/docker/Dockerfile.prod.erb')
      expect(File.exist?(path)).to be true
    end

    it 'resolves static file path through inheritance chain' do
      path = described_class.resolve_static_path('docker/Dockerfile.prod.erb', '7.2.0')
      expect(path).to end_with('rails-8.1/docker/Dockerfile.prod.erb')
    end

    it 'raises TemplateNotFoundError for missing file' do
      expect { described_class.resolve_static_path('nonexistent/file.txt', '8.1.0') }
        .to raise_error(Moduloproject::TemplateEngine::TemplateNotFoundError, /Static file not found/)
    end
  end

  describe '.inheritance_chain_for' do
    it 'returns inheritance chain for Rails 7.2' do
      chain = described_class.inheritance_chain_for('7.2.0')
      expect(chain.versions).to eq(%w[rails-7.2 rails-8.0 rails-8.1])
    end

    it 'returns inheritance chain for Rails 8.1' do
      chain = described_class.inheritance_chain_for('8.1.0')
      expect(chain.versions).to eq(['rails-8.1'])
    end
  end

  describe '.normalize_version' do
    it 'normalizes version strings' do
      expect(described_class.normalize_version('8.1.0')).to eq('rails-8.1')
      expect(described_class.normalize_version('7.2.3')).to eq('rails-7.2')
      expect(described_class.normalize_version('rails-8.0')).to eq('rails-8.0')
    end
  end

  describe '.reset!' do
    it 'clears cached instances' do
      # Access to initialize caches
      described_class.templates_root
      described_class.default_version

      # Reset should not raise
      expect { described_class.reset! }.not_to raise_error
    end
  end
end

RSpec.describe Moduloproject::TemplateEngine::TemplateBinding do
  let(:context) do
    Moduloproject::Context.new(
      project_root: '/tmp/test',
      project_name: 'test-app',
      ruby_version: '3.3.0',
      rails_version: '8.1.0'
    )
  end

  let(:binding_instance) { described_class.new(context) }

  it 'exposes context attributes as methods' do
    erb_binding = binding_instance.binding_for_erb
    expect(erb_binding.eval('project_name')).to eq('test-app')
    expect(erb_binding.eval('ruby_version')).to eq('3.3.0')
  end

  it 'sets legacy instance variables' do
    erb_binding = binding_instance.binding_for_erb
    expect(erb_binding.eval('@data')).to eq(context)
    expect(erb_binding.eval('@adapter')).to eq('postgresql')
  end
end
