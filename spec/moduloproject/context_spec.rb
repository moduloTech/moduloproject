# frozen_string_literal: true

RSpec.describe Moduloproject::Context do
  describe '#initialize' do
    context 'with default values' do
      subject(:context) { described_class.new }

      it 'sets project_root to current directory' do
        expect(context.project_root).to eq(Dir.pwd)
      end

      it 'derives project_name from directory' do
        expect(context.project_name).to eq(File.basename(Dir.pwd))
      end

      it 'uses current Ruby version' do
        expect(context.ruby_version).to eq(RUBY_VERSION)
      end

      it 'defaults to Rails 8.1.0' do
        expect(context.rails_version).to eq('8.1.0')
      end

      it 'defaults to postgresql adapter' do
        expect(context.adapter).to eq('postgresql')
      end

      it 'defaults to importmap js engine' do
        expect(context.js_engine).to eq(:importmap)
      end

      it 'generates parameterized image_name' do
        expect(context.image_name).to be_a(String)
        expect(context.image_name).not_to include(' ')
      end
    end

    context 'with custom values' do
      subject(:context) do
        described_class.new(
          project_root: '/tmp/myproject',
          project_name: 'My Cool Project',
          ruby_version: '3.3.0',
          rails_version: '7.2.0',
          adapter: 'mysql2',
          js_engine: :bun,
          frontend: 'vue',
          production_url: 'myapp.com',
          staging_url: 'staging.myapp.com',
          review_base_url: 'review.myapp.com'
        )
      end

      it 'uses provided values' do
        expect(context.project_root).to eq('/tmp/myproject')
        expect(context.project_name).to eq('My Cool Project')
        expect(context.ruby_version).to eq('3.3.0')
        expect(context.rails_version).to eq('7.2.0')
        expect(context.adapter).to eq('mysql2')
        expect(context.js_engine).to eq(:bun)
        expect(context.frontend).to eq('vue')
        expect(context.production_url).to eq('myapp.com')
        expect(context.staging_url).to eq('staging.myapp.com')
        expect(context.review_base_url).to eq('review.myapp.com')
      end

      it 'generates correct image_name' do
        expect(context.image_name).to eq('my-cool-project')
      end

      it 'generates correct environment_name' do
        expect(context.environment_name).to eq('MY_COOL_PROJECT')
      end
    end
  end

  describe '#mysql?' do
    it 'returns true for mysql adapter' do
      context = described_class.new(adapter: 'mysql2')
      expect(context.mysql?).to be true
    end

    it 'returns false for postgresql adapter' do
      context = described_class.new(adapter: 'postgresql')
      expect(context.mysql?).to be false
    end
  end

  describe '#postgresql?' do
    it 'returns false for mysql adapter' do
      context = described_class.new(adapter: 'mysql2')
      expect(context.postgresql?).to be false
    end

    it 'returns true for postgresql adapter' do
      context = described_class.new(adapter: 'postgresql')
      expect(context.postgresql?).to be true
    end

    it 'returns false for sqlite3 adapter' do
      context = described_class.new(adapter: 'sqlite3')
      expect(context.postgresql?).to be false
    end
  end

  describe '#sqlite3?' do
    it 'returns true for sqlite3 adapter' do
      context = described_class.new(adapter: 'sqlite3')
      expect(context.sqlite3?).to be true
    end

    it 'returns false for postgresql adapter' do
      context = described_class.new(adapter: 'postgresql')
      expect(context.sqlite3?).to be false
    end

    it 'returns false for mysql adapter' do
      context = described_class.new(adapter: 'mysql2')
      expect(context.sqlite3?).to be false
    end
  end

  describe '#webpacker?' do
    it 'returns true for webpacker engine' do
      context = described_class.new(js_engine: :webpacker)
      expect(context.webpacker?).to be true
    end

    it 'returns false for other engines' do
      context = described_class.new(js_engine: :bun)
      expect(context.webpacker?).to be false
    end
  end

  describe '#bun?' do
    it 'returns true for bun engine' do
      context = described_class.new(js_engine: :bun)
      expect(context.bun?).to be true
    end

    it 'returns false for other engines' do
      context = described_class.new(js_engine: :importmap)
      expect(context.bun?).to be false
    end
  end

  describe '#importmap?' do
    it 'returns true for importmap engine' do
      context = described_class.new(js_engine: :importmap)
      expect(context.importmap?).to be true
    end

    it 'returns false for other engines' do
      context = described_class.new(js_engine: :bun)
      expect(context.importmap?).to be false
    end
  end

  describe '#vue?' do
    it 'returns true for vue frontend' do
      context = described_class.new(frontend: 'vue')
      expect(context.vue?).to be true
    end

    it 'returns false for hotwire frontend' do
      context = described_class.new(frontend: 'hotwire')
      expect(context.vue?).to be false
    end

    it 'returns false for nil frontend' do
      context = described_class.new
      expect(context.vue?).to be false
    end
  end

  describe '#hotwire?' do
    it 'returns true for hotwire frontend' do
      context = described_class.new(frontend: 'hotwire')
      expect(context.hotwire?).to be true
    end

    it 'returns false for vue frontend' do
      context = described_class.new(frontend: 'vue')
      expect(context.hotwire?).to be false
    end
  end

  describe '#rails_version_gte?' do
    subject(:context) { described_class.new(rails_version: '8.0.0') }

    it 'returns true for lower versions' do
      expect(context.rails_version_gte?('7.2')).to be true
    end

    it 'returns true for equal versions' do
      expect(context.rails_version_gte?('8.0.0')).to be true
    end

    it 'returns false for higher versions' do
      expect(context.rails_version_gte?('8.1.0')).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash of all attributes' do
      context = described_class.new(project_name: 'test')
      hash = context.to_h

      expect(hash).to be_a(Hash)
      expect(hash.keys).to include(:project_root, :project_name, :ruby_version, :rails_version)
    end
  end
end
