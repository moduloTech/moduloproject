# frozen_string_literal: true

RSpec.shared_examples 'config files' do |combination|
  describe 'config files' do
    it 'creates config/database.yml' do
      path = File.join(project_root, 'config/database.yml')
      expect(File.exist?(path)).to be true
    end

    it 'config/database.yml references correct adapter' do
      content = File.read(File.join(project_root, 'config/database.yml'))
      case combination.database
      when 'postgresql'
        expect(content).to match(/postgresql|postgres/)
      when 'mysql2'
        expect(content).to include('mysql2')
      when 'sqlite3'
        expect(content).to include('sqlite3')
      end
    end

    describe 'config/database.yml structure' do
      let(:database_yml) { File.read(File.join(project_root, 'config/database.yml')) }

      if %w[postgresql mysql2].include?(combination.database)
        it 'has development section with &default anchor' do
          expect(database_yml).to match(/^development: &default$/)
        end

        it 'has test section inheriting from default' do
          expect(database_yml).to match(/^test:\n\s+<<: \*default$/)
        end

        it 'has staging section inheriting from default' do
          expect(database_yml).to match(/^staging:\n\s+<<: \*default$/)
        end

        it 'has production section inheriting from default' do
          expect(database_yml).to match(/^production:\n\s+<<: \*default$/)
        end
      end

      case combination.database
      when 'postgresql'
        it 'has postgresql adapter in development' do
          expect(database_yml).to include('adapter: postgresql')
        end

        it 'has correct development DATABASE_URL with project name' do
          expect(database_yml).to include(
            "ENV.fetch('DATABASE_URL', 'postgresql://postgres:postgres@database/#{combination.app_name}')"
          )
        end

        it 'has correct test DATABASE_TEST_URL with project name' do
          expect(database_yml).to include(
            "ENV.fetch('DATABASE_TEST_URL', 'postgresql://postgres:postgres@database/#{combination.app_name}-test')"
          )
        end

      when 'mysql2'
        it 'has mysql2 adapter in development' do
          expect(database_yml).to include('adapter: mysql2')
        end

        it 'has correct development DATABASE_URL with project name' do
          expect(database_yml).to include(
            "ENV.fetch('DATABASE_URL', 'mysql2://root@database/#{combination.app_name}')"
          )
        end

        it 'has correct test DATABASE_TEST_URL with project name' do
          expect(database_yml).to include(
            "ENV.fetch('DATABASE_TEST_URL', 'mysql2://root@database/#{combination.app_name}-test')"
          )
        end

      when 'sqlite3'
        it 'uses sqlite3 adapter from Rails defaults' do
          expect(database_yml).to include('adapter: sqlite3')
        end
      end
    end

    it 'creates config/cable.yml' do
      expect(File.exist?(File.join(project_root, 'config/cable.yml'))).to be true
    end

    it 'creates config/puma.rb with valid Ruby syntax' do
      path = File.join(project_root, 'config/puma.rb')
      expect(File.exist?(path)).to be true
      expect(path).to have_valid_ruby_syntax
    end
  end
end
