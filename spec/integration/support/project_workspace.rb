# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module IntegrationTests
  module ProjectWorkspace
    BASE_DIR = if RUBY_PLATFORM.include?('darwin')
                 '/private/tmp/moduloproject_integration'
               else
                 File.join(Dir.tmpdir, 'moduloproject_integration')
               end

    def self.create(combination)
      workspace = File.join(BASE_DIR, combination.label)
      FileUtils.rm_rf(workspace)
      FileUtils.mkdir_p(workspace)
      workspace
    end

    def self.project_root(workspace, combination)
      File.join(workspace, combination.app_name)
    end

    def self.cleanup(workspace)
      FileUtils.rm_rf(workspace) if workspace&.start_with?(BASE_DIR)
    end

    def self.cleanup_all
      FileUtils.rm_rf(BASE_DIR)
    end
  end
end
