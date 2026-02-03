# frozen_string_literal: true

RSpec.describe Moduloproject::TemplateEngine::Renderer do
  let(:context) do
    Moduloproject::Context.new(
      project_root: '/tmp/test',
      project_name: 'test-app',
      ruby_version: '3.3.0',
      rails_version: '8.1.0',
      adapter: 'postgresql'
    )
  end

  subject { described_class.new }

  describe '#render' do
    it 'renders ERB content with context' do
      template = '<%= project_name %> uses Ruby <%= ruby_version %>'
      result = subject.render(template, context)
      expect(result).to eq('test-app uses Ruby 3.3.0')
    end

    it 'provides helper methods' do
      template = 'PostgreSQL: <%= postgresql? %>, MySQL: <%= mysql? %>'
      result = subject.render(template, context)
      expect(result).to eq('PostgreSQL: true, MySQL: false')
    end

    it 'provides rails_version_gte? helper' do
      template = 'Rails 7.2+: <%= rails_version_gte?("7.2") %>'
      result = subject.render(template, context)
      expect(result).to eq('Rails 7.2+: true')
    end

    it 'supports ERB trim mode' do
      template = "<%- if true -%>\ntrimmed\n<%- end -%>"
      result = subject.render(template, context)
      expect(result).to eq("trimmed\n")
    end
  end

  describe '#render with partials' do
    let(:templates_root) { Moduloproject::TemplateEngine.templates_root }
    let(:loader) { Moduloproject::TemplateEngine::Loader.new(templates_root) }

    it 'renders partials when loader is provided' do
      template = '<%= partial("ruby_install") %>'
      result = subject.render(template, context, loader: loader)
      expect(result).to include('apk add')
    end

    it 'raises error when partial called without loader' do
      template = '<%= partial("ruby_install") %>'
      expect { subject.render(template, context) }
        .to raise_error(/No loader configured for partials/)
    end
  end
end

RSpec.describe Moduloproject::TemplateEngine::TemplateBinding do
  let(:context) do
    Moduloproject::Context.new(
      project_root: '/tmp/test',
      project_name: 'test-app',
      ruby_version: '3.3.0',
      rails_version: '8.1.0',
      adapter: 'postgresql',
      js_engine: :importmap,
      image_name: 'test-app',
      environment_name: 'TEST_APP',
      production_url: 'https://test.com',
      staging_url: 'https://staging.test.com',
      review_base_url: 'https://review.test.com'
    )
  end

  describe '#binding_for_erb' do
    let(:binding_instance) { described_class.new(context) }

    it 'exposes context attributes as methods' do
      erb_binding = binding_instance.binding_for_erb
      expect(erb_binding.eval('project_name')).to eq('test-app')
      expect(erb_binding.eval('ruby_version')).to eq('3.3.0')
      expect(erb_binding.eval('rails_version')).to eq('8.1.0')
    end

    it 'exposes helper methods' do
      erb_binding = binding_instance.binding_for_erb
      expect(erb_binding.eval('postgresql?')).to be true
      expect(erb_binding.eval('mysql?')).to be false
      expect(erb_binding.eval('importmap?')).to be true
      expect(erb_binding.eval('webpacker?')).to be false
      expect(erb_binding.eval('bun?')).to be false
    end

    it 'exposes rails_version_gte?' do
      erb_binding = binding_instance.binding_for_erb
      expect(erb_binding.eval('rails_version_gte?("7.2")')).to be true
      expect(erb_binding.eval('rails_version_gte?("9.0")')).to be false
    end

    it 'sets legacy instance variables' do
      erb_binding = binding_instance.binding_for_erb
      expect(erb_binding.eval('@data')).to eq(context)
      expect(erb_binding.eval('@adapter')).to eq('postgresql')
      expect(erb_binding.eval('@js_engine')).to eq(:importmap)
      expect(erb_binding.eval('@image_name')).to eq('test-app')
      expect(erb_binding.eval('@environment_name')).to eq('TEST_APP')
      expect(erb_binding.eval('@production_url')).to eq('https://test.com')
      expect(erb_binding.eval('@staging_url')).to eq('https://staging.test.com')
      expect(erb_binding.eval('@review_base_url')).to eq('https://review.test.com')
      expect(erb_binding.eval('@rails_72_and_more')).to be true
    end
  end

  describe '#partial' do
    let(:templates_root) { Moduloproject::TemplateEngine.templates_root }
    let(:loader) { Moduloproject::TemplateEngine::Loader.new(templates_root) }
    let(:binding_instance) { described_class.new(context, loader: loader) }

    it 'renders a partial' do
      result = binding_instance.partial('ruby_install')
      expect(result).to include('apk add')
    end

    it 'renders partial with context variables' do
      result = binding_instance.partial('database_packages')
      expect(result).to include('postgresql-client')
      expect(result).not_to include('mysql-client')
    end

    context 'with MySQL adapter' do
      let(:mysql_context) do
        Moduloproject::Context.new(
          project_root: '/tmp/test',
          project_name: 'test-app',
          ruby_version: '3.3.0',
          rails_version: '8.1.0',
          adapter: 'mysql2'
        )
      end
      let(:mysql_binding) { described_class.new(mysql_context, loader: loader) }

      it 'renders partial with MySQL packages' do
        result = mysql_binding.partial('database_packages')
        expect(result).to include('mysql-client')
        expect(result).not_to include('postgresql-client')
      end
    end
  end
end
