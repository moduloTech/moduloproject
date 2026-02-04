# frozen_string_literal: true

RSpec.shared_examples 'application.rb content' do |combination|
  describe 'config/application.rb' do
    let(:application_rb) { File.join(project_root, 'config/application.rb') }

    it 'exists' do
      expect(File.exist?(application_rb)).to be true
    end

    it 'has valid Ruby syntax' do
      expect(application_rb).to have_valid_ruby_syntax
    end

    if combination.active_job == 'sidekiq'
      it 'configures queue_adapter as :sidekiq' do
        content = File.read(application_rb)
        expect(content).to match(/queue_adapter\s*=\s*:sidekiq/)
      end
    end

    if combination.rails_cache == 'redis'
      it 'configures redis_cache_store' do
        content = File.read(application_rb)
        expect(content).to include(':redis_cache_store')
      end
    end
  end
end
