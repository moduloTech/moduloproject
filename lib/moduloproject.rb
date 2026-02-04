# frozen_string_literal: true

require_relative 'moduloproject/version'

module Moduloproject
  autoload :CLI, 'moduloproject/cli'
  autoload :Context, 'moduloproject/context'
  autoload :Generators, 'moduloproject/generators'
  autoload :ModulorailsSetup, 'moduloproject/modulorails_setup'
  autoload :RailsGenerator, 'moduloproject/rails_generator'
  autoload :Recipe, 'moduloproject/recipe'
  autoload :TemplateEngine, 'moduloproject/template_engine'
  autoload :VersionCheck, 'moduloproject/version_check'
  autoload :ViteSetup, 'moduloproject/vite_setup'

  # Backend strategies
  module Backends
    autoload :ActiveJob, 'moduloproject/backends/active_job'
    autoload :ActionCable, 'moduloproject/backends/action_cable'
    autoload :RailsCache, 'moduloproject/backends/rails_cache'
  end

  # Setup orchestrators
  module Setup
    autoload :ActiveJobSetup, 'moduloproject/setup/active_job_setup'
    autoload :ActionCableSetup, 'moduloproject/setup/action_cable_setup'
    autoload :RailsCacheSetup, 'moduloproject/setup/rails_cache_setup'
    autoload :SolidCleanup, 'moduloproject/setup/solid_cleanup'
  end

  # Commands namespace
  module Commands
    autoload :New, 'moduloproject/commands/new'
  end
end
