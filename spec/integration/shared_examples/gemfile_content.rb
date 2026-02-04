# frozen_string_literal: true

RSpec.shared_examples 'gemfile content' do |combination|
  describe 'Gemfile content' do
    let(:gemfile_path) { File.join(project_root, 'Gemfile') }

    it 'contains modulorails gem' do
      expect(gemfile_path).to contain_gem('modulorails')
    end

    if combination.frontend == 'vue'
      it 'contains vite_rails gem' do
        expect(gemfile_path).to contain_gem('vite_rails')
      end
    end

    if combination.active_job == 'sidekiq'
      it 'contains sidekiq gem' do
        expect(gemfile_path).to contain_gem('sidekiq')
      end
    end

    if combination.uses_redis?
      it 'contains redis gem' do
        expect(gemfile_path).to contain_gem('redis')
      end
    end

    # Database adapter gem
    case combination.database
    when 'postgresql'
      it 'contains pg gem' do
        expect(gemfile_path).to contain_gem('pg')
      end
    when 'mysql2'
      it 'contains mysql2 gem' do
        expect(gemfile_path).to contain_gem('mysql2')
      end
    when 'sqlite3'
      it 'contains sqlite3 gem' do
        expect(gemfile_path).to contain_gem('sqlite3')
      end
    end

    # Solid gems for Rails 8.0/8.1
    if combination.supports_skip_solid?
      if combination.skip_solid_passed?
        # All non-solid: --skip-solid was passed, no solid gems expected
        %w[solid_queue solid_cable solid_cache].each do |gem_name|
          it "does not contain #{gem_name} gem (skip_solid passed)" do
            expect(gemfile_path).not_to contain_gem(gem_name)
          end
        end
      elsif combination.needs_solid_cleanup?
        # Mixed: only active solid backends should have their gems
        { 'solid_queue' => combination.active_job,
          'solid_cable' => combination.action_cable,
          'solid_cache' => combination.rails_cache }.each do |gem_name, backend|
          if backend == gem_name
            it "contains #{gem_name} gem (active solid backend)" do
              expect(gemfile_path).to contain_gem(gem_name)
            end
          else
            it "does not contain #{gem_name} gem (cleaned up)" do
              expect(gemfile_path).not_to contain_gem(gem_name)
            end
          end
        end
      end
    end
  end
end
