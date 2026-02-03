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

  describe Moduloproject::TemplateEngine::TemplateBinding do
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
end
