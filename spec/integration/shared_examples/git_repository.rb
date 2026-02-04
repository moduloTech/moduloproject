# frozen_string_literal: true

RSpec.shared_examples 'git repository' do |_combination|
  describe 'git repository' do
    it 'has .git directory' do
      expect(Dir.exist?(File.join(project_root, '.git'))).to be true
    end

    it 'has initial commit' do
      Dir.chdir(project_root) do
        log_output = `git log --oneline 2>&1`
        expect(log_output).to include('Initial commit via moduloproject')
      end
    end
  end
end
