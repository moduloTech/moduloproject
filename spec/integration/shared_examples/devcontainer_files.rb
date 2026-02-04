# frozen_string_literal: true

RSpec.shared_examples 'devcontainer files' do |_combination|
  describe '.devcontainer files' do
    it 'creates devcontainer.json with valid JSON' do
      path = File.join(project_root, '.devcontainer/devcontainer.json')
      expect(File.exist?(path)).to be true
      expect(path).to have_valid_json
    end

    it 'creates compose.yml with valid YAML' do
      path = File.join(project_root, '.devcontainer/compose.yml')
      expect(File.exist?(path)).to be true
      expect(path).to have_valid_yaml
    end

    it 'creates Dockerfile' do
      expect(File.exist?(File.join(project_root, '.devcontainer/Dockerfile'))).to be true
    end
  end
end
