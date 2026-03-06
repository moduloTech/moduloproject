# frozen_string_literal: true

RSpec.shared_examples 'git repository' do |combination|
  describe 'git repository' do
    it 'has .git directory' do
      expect(Dir.exist?(File.join(project_root, '.git'))).to be true
    end

    it 'has initial commit with configuration details' do
      Dir.chdir(project_root) do
        log_output = `git log --oneline 2>&1`
        expect(log_output).to include('Initial commit via moduloproject')

        body = `git log -1 --format=%b 2>&1`
        expect(body).to include("Ruby: #{combination.ruby}")
        expect(body).to include("Rails: #{combination.rails}")
        expect(body).to include("Database: #{combination.database}")
        expect(body).to include("Frontend: #{combination.frontend}")
        expect(body).to include("Active Job: #{combination.active_job}")
        expect(body).to include("Action Cable: #{combination.action_cable}")
        expect(body).to include("Rails Cache: #{combination.rails_cache}")
      end
    end
  end
end
