# Phase 2 - Generators

**Estimate:** 3 days

## Objectives

- Extract generators from Modulorails
- Remove Rails::Generators dependency
- Adapt to standalone execution

## Structure

```
lib/moduloproject/
└── generators/
    ├── base.rb
    ├── docker.rb
    ├── gitlab_ci.rb
    ├── devcontainer.rb
    ├── claude_code.rb
    └── git_hooks.rb
```

## Base Generator

```ruby
# lib/moduloproject/generators/base.rb
module Moduloproject
  module Generators
    class Base
      attr_reader :context, :options

      def initialize(context, options = {})
        @context = context
        @options = options
      end

      def generate
        raise NotImplementedError
      end

      private

      def render_template(template_path)
        template = Moduloproject::TemplateEngine.load(template_path, context)
        template.render
      end

      def write_file(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end

      def file_exists?(path)
        File.exist?(path)
      end

      def project_root
        context.project_root || Dir.pwd
      end
    end
  end
end
```

## Migration from Modulorails

| Modulorails class | Moduloproject class | Key changes |
|-------------------|---------------------|-------------|
| `Modulorails::DockerGenerator` | `Generators::Docker` | No Rails::Generators, pure Ruby |
| `Modulorails::GitlabciGenerator` | `Generators::GitlabCi` | No Rails::Generators, pure Ruby |
| `Modulorails::GitHooksGenerator` | `Generators::GitHooks` | No Rails::Generators, pure Ruby |
| `Modulorails::DevcontainerGenerator` | `Generators::Devcontainer` | No Rails::Generators, pure Ruby |
| `Modulorails::ClaudeCodeGenerator` | `Generators::ClaudeCode` | Enhanced with MCP config |

## Docker Generator

```ruby
# lib/moduloproject/generators/docker.rb
module Moduloproject
  module Generators
    class Docker < Base
      FILES = %w[
        Dockerfile.prod
        compose.yml
        compose.override.yml
      ].freeze

      def generate
        FILES.each do |file|
          content = render_template("docker/#{file}.erb")
          write_file(File.join(project_root, file), content)
        end
      end
    end
  end
end
```

## GitLab CI Generator

```ruby
# lib/moduloproject/generators/gitlab_ci.rb
module Moduloproject
  module Generators
    class GitlabCi < Base
      def generate
        content = render_template("ci/.gitlab-ci.yml.erb")
        write_file(File.join(project_root, ".gitlab-ci.yml"), content)
      end
    end
  end
end
```

## Devcontainer Generator

```ruby
# lib/moduloproject/generators/devcontainer.rb
module Moduloproject
  module Generators
    class Devcontainer < Base
      def generate
        content = render_template("devcontainer/devcontainer.json.erb")
        write_file(File.join(project_root, ".devcontainer", "devcontainer.json"), content)
      end
    end
  end
end
```

## Git Hooks Generator

```ruby
# lib/moduloproject/generators/git_hooks.rb
module Moduloproject
  module Generators
    class GitHooks < Base
      HOOKS = %w[pre-commit post-rewrite].freeze

      def generate
        HOOKS.each do |hook|
          content = render_template("git_hooks/#{hook}.erb")
          path = File.join(project_root, ".git", "hooks", hook)
          write_file(path, content)
          FileUtils.chmod(0o755, path)
        end
      end
    end
  end
end
```

## Claude Code Generator

```ruby
# lib/moduloproject/generators/claude_code.rb
module Moduloproject
  module Generators
    class ClaudeCode < Base
      def generate
        generate_settings
        generate_claude_md
      end

      private

      def generate_settings
        content = render_template("claude/settings.json.erb")
        write_file(File.join(project_root, ".claude", "settings.json"), content)
      end

      def generate_claude_md
        content = render_template("claude/CLAUDE.md.erb")
        write_file(File.join(project_root, ".claude", "CLAUDE.md"), content)
      end
    end
  end
end
```

## Generator Registry

```ruby
# lib/moduloproject/generators.rb
module Moduloproject
  module Generators
    REGISTRY = {
      docker: Docker,
      ci: GitlabCi,
      devcontainer: Devcontainer,
      claude: ClaudeCode,
      hooks: GitHooks
    }.freeze

    def self.run(component, context, options = {})
      generator_class = REGISTRY[component.to_sym]
      raise ArgumentError, "Unknown component: #{component}" unless generator_class

      generator_class.new(context, options).generate
    end

    def self.run_all(context, options = {})
      REGISTRY.each_key do |component|
        run(component, context, options)
      end
    end
  end
end
```

## Deliverables

- [ ] Base generator class
- [ ] Docker generator (extracted from Modulorails)
- [ ] GitLab CI generator (extracted from Modulorails)
- [ ] Devcontainer generator (extracted from Modulorails)
- [ ] Git hooks generator (extracted from Modulorails)
- [ ] Claude Code generator (enhanced)
- [ ] Generator registry
- [ ] Unit tests for each generator
