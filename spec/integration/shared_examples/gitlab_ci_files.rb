# frozen_string_literal: true

RSpec.shared_examples 'gitlab ci files' do |combination|
  describe 'GitLab CI files' do
    it 'creates .gitlab-ci.yml with valid YAML' do
      path = File.join(project_root, '.gitlab-ci.yml')
      expect(File.exist?(path)).to be true
      expect(path).to have_valid_yaml
    end

    it 'creates bin/test as executable' do
      expect(File.join(project_root, 'bin/test')).to be_executable_file
    end

    it 'bin/test has valid shell syntax' do
      expect(File.join(project_root, 'bin/test')).to have_valid_shell_syntax
    end

    describe '.gitlab-ci.yml content' do
      let(:ci_content) { File.read(File.join(project_root, '.gitlab-ci.yml')) }

      it 'includes test job' do
        expect(ci_content).to include('test:')
      end

      it 'includes seeds job' do
        expect(ci_content).to include('seeds:')
        expect(ci_content).to include('db:seed')
      end

      it 'includes rubocop job' do
        expect(ci_content).to include('rubocop:')
      end

      it 'includes rubocop_light job' do
        expect(ci_content).to include('rubocop_light:')
      end

      it 'includes bundleraudit job' do
        expect(ci_content).to include('bundleraudit:')
      end

      it 'includes brakeman job' do
        expect(ci_content).to include('brakeman:')
      end

      if combination.database == 'postgresql'
        it 'uses PostgreSQL service' do
          expect(ci_content).to include('postgres:16-alpine')
        end

        it 'does not use MySQL service' do
          expect(ci_content).not_to include('mysql:')
        end
      elsif combination.database == 'mysql2'
        it 'uses MySQL service' do
          expect(ci_content).to include('mysql:8-alpine')
        end

        it 'does not use PostgreSQL service' do
          expect(ci_content).not_to include('postgres:')
        end
      elsif combination.database == 'sqlite3'
        it 'does not use PostgreSQL or MySQL services' do
          expect(ci_content).not_to include('postgres:')
          expect(ci_content).not_to include('mysql:')
        end

        it 'does not include DATABASE_TEST_URL' do
          expect(ci_content).not_to include('DATABASE_TEST_URL')
        end
      end

      if combination.frontend == 'vue'
        it 'includes vitest job for vue' do
          expect(ci_content).to include('vitest:')
        end

        it 'includes eslint job for vue' do
          expect(ci_content).to include('eslint:')
        end
      else
        it 'excludes vitest job for hotwire' do
          expect(ci_content).not_to include('vitest:')
        end

        it 'excludes eslint job for hotwire' do
          expect(ci_content).not_to include('eslint:')
        end
      end
    end

    describe 'CI runner' do
      rails_version = Gem::Version.new("#{combination.rails}.0")

      if rails_version >= Gem::Version.new('8.1')
        it 'creates config/ci.rb for Rails >= 8.1' do
          ci_runner = File.join(project_root, 'config/ci.rb')
          expect(File.exist?(ci_runner)).to be true

          content = File.read(ci_runner)
          expect(content).to include('CI.run do')
        end
      else
        it 'creates bin/ci for Rails < 8.1' do
          ci_runner = File.join(project_root, 'bin/ci')
          expect(File.exist?(ci_runner)).to be true
          expect(File.executable?(File.join(project_root, 'bin/ci'))).to be true

          content = File.read(ci_runner)
          expect(content).to include('class CiRunner')
        end
      end
    end
  end
end
