# frozen_string_literal: true

RSpec.shared_examples 'rails boilerplate' do |combination|
  describe 'Rails boilerplate files' do
    %w[
      Gemfile
      Gemfile.lock
      Rakefile
      config.ru
      app/controllers/application_controller.rb
      app/models/application_record.rb
      config/routes.rb
      config/application.rb
      config/environment.rb
      config/environments/development.rb
      config/environments/production.rb
      config/environments/test.rb
    ].each do |file|
      it "has #{file}" do
        expect(File.exist?(File.join(project_root, file))).to be true
      end
    end

    it 'Gemfile contains correct database gem' do
      gemfile = File.join(project_root, 'Gemfile')
      case combination.database
      when 'postgresql'
        expect(gemfile).to contain_gem('pg')
      when 'mysql2'
        expect(gemfile).to contain_gem('mysql2')
      when 'sqlite3'
        expect(gemfile).to contain_gem('sqlite3')
      end
    end

    it 'Gemfile.lock exists and is non-empty' do
      path = File.join(project_root, 'Gemfile.lock')
      expect(File.exist?(path)).to be true
      expect(File.size(path)).to be > 0
    end

    describe 'README.md content' do
      let(:readme) { File.read(File.join(project_root, 'README.md')) }

      it 'exists and is non-empty' do
        expect(File.exist?(File.join(project_root, 'README.md'))).to be true
        expect(readme.strip).not_to be_empty
      end

      it 'contains a title' do
        expect(readme).to match(/^# /)
      end

      it 'mentions Ruby version' do
        expect(readme).to match(/ruby version/i)
      end

      it 'mentions database' do
        expect(readme).to match(/database/i)
      end

      it 'mentions deployment' do
        expect(readme).to match(/deployment/i)
      end
    end
  end
end
