# frozen_string_literal: true

require_relative 'lib/moduloproject/version'

Gem::Specification.new do |spec|
  spec.name          = 'moduloproject'
  spec.version       = Moduloproject::VERSION
  spec.authors       = ['Modulotech']
  spec.email         = ['ciappa_m@modulotech.fr']

  spec.summary       = 'CLI tool for bootstrapping and managing Modulotech Rails projects'
  spec.description   = 'A comprehensive CLI tool for creating new Rails projects with Modulotech ' \
                       'conventions, syncing templates, and managing project configurations.'
  spec.homepage      = 'https://github.com/moduloTech/moduloproject'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    git_files = `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?('bin/', 'spec/', '.git', '.rubocop', 'Gemfile')
    end
    # Include templates directory which may not be tracked yet
    template_files = Dir.glob('templates/**/*').select { |f| File.file?(f) }
    (git_files + template_files).uniq
  end
  spec.bindir        = 'exe'
  spec.executables   = ['moduloproject']
  spec.require_paths = ['lib']

  spec.add_dependency 'diffy', '~> 3.4'
  spec.add_dependency 'gitlab', '~> 4.0'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'tty-box', '~> 0.7'
  spec.add_dependency 'tty-prompt', '~> 0.23'
end
