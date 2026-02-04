# frozen_string_literal: true

RSpec.shared_examples 'git hooks files' do |_combination|
  describe 'git hooks files' do
    %w[bin/dc bin/dcr bin/refresh_generations].each do |script|
      it "creates #{script} as executable" do
        expect(File.join(project_root, script)).to be_executable_file
      end

      it "#{script} has valid shell syntax" do
        expect(File.join(project_root, script)).to have_valid_shell_syntax
      end
    end

    it 'creates .gitattributes' do
      expect(File.exist?(File.join(project_root, '.gitattributes'))).to be true
    end

    it 'creates .git/hooks/post-rewrite as executable' do
      expect(File.join(project_root, '.git/hooks/post-rewrite')).to be_executable_file
    end

    it '.git/hooks/post-rewrite has valid shell syntax' do
      expect(File.join(project_root, '.git/hooks/post-rewrite')).to have_valid_shell_syntax
    end

    it 'creates .git/hooks/pre-merge-commit as executable' do
      expect(File.join(project_root, '.git/hooks/pre-merge-commit')).to be_executable_file
    end

    it '.git/hooks/pre-merge-commit has valid shell syntax' do
      expect(File.join(project_root, '.git/hooks/pre-merge-commit')).to have_valid_shell_syntax
    end
  end
end
