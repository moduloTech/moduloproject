# frozen_string_literal: true

require_relative 'moduloproject/version'

module Moduloproject
  autoload :CLI, 'moduloproject/cli'
  autoload :Context, 'moduloproject/context'
  autoload :Generators, 'moduloproject/generators'
  autoload :TemplateEngine, 'moduloproject/template_engine'
  autoload :VersionCheck, 'moduloproject/version_check'
end
