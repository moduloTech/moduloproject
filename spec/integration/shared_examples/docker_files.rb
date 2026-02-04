# frozen_string_literal: true

RSpec.shared_examples 'docker files' do |combination|
  describe 'Docker files' do
    it 'creates Dockerfile' do
      expect(File.exist?(File.join(project_root, 'Dockerfile'))).to be true
    end

    it 'Dockerfile references correct Ruby version' do
      content = File.read(File.join(project_root, 'Dockerfile'))
      expect(content).to include(combination.ruby_version)
    end

    it 'Dockerfile references alpine image' do
      content = File.read(File.join(project_root, 'Dockerfile'))
      expect(content).to include('alpine')
    end

    it 'Dockerfile includes correct database packages' do
      content = File.read(File.join(project_root, 'Dockerfile'))
      case combination.database
      when 'postgresql'
        expect(content).to match(/postgresql|libpq/)
      when 'mysql2'
        expect(content).to match(/mysql/)
      when 'sqlite3'
        expect(content).to match(/sqlite/)
      end
    end

    it 'creates .dockerignore' do
      expect(File.exist?(File.join(project_root, '.dockerignore'))).to be true
    end

    it 'creates bin/docker-entrypoint as executable' do
      expect(File.join(project_root, 'bin/docker-entrypoint')).to be_executable_file
    end

    it 'bin/docker-entrypoint has valid shell syntax' do
      expect(File.join(project_root, 'bin/docker-entrypoint')).to have_valid_shell_syntax
    end
  end
end
