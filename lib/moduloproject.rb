# frozen_string_literal: true

require_relative 'moduloproject/version'

module Moduloproject
  autoload :CLI, 'moduloproject/cli'
  autoload :VersionCheck, 'moduloproject/version_check'
end
