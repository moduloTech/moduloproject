# frozen_string_literal: true

RSpec.shared_examples 'tracking file' do |_combination|
  describe '.moduloproject.yml' do
    it 'exists with valid YAML' do
      path = File.join(project_root, '.moduloproject.yml')
      expect(File.exist?(path)).to be true
      expect(path).to have_valid_yaml
    end

    it 'contains generator version keys' do
      content = YAML.safe_load_file(File.join(project_root, '.moduloproject.yml'))
      expect(content).to be_a(Hash)
      expect(content.keys).to include('docker', 'devcontainer', 'config', 'gitlab_ci', 'git_hooks', 'claude_code')
    end
  end
end
