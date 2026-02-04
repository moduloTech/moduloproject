# frozen_string_literal: true

RSpec.shared_examples 'production.rb content' do |combination|
  describe 'config/environments/production.rb' do
    let(:production_rb) { File.join(project_root, 'config/environments/production.rb') }

    it 'exists' do
      expect(File.exist?(production_rb)).to be true
    end

    it 'has valid Ruby syntax' do
      expect(production_rb).to have_valid_ruby_syntax
    end

    if combination.rails_cache == 'redis' && combination.supports_skip_solid?
      it 'does not reference solid_cache_store' do
        content = File.read(production_rb)
        expect(content).not_to include(':solid_cache_store')
      end
    end
  end
end
