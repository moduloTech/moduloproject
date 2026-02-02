# Phase 3 - Templates

**Estimate:** 2 days

## Objectives

- Implement template loader with inheritance
- ERB renderer with context
- Template inheritance system

## Structure

```
lib/moduloproject/
└── template_engine/
    ├── loader.rb
    ├── renderer.rb
    └── inheritance.rb

templates/
├── rails-8.1/
│   ├── manifest.yml
│   ├── docker/
│   ├── ci/
│   ├── devcontainer/
│   ├── claude/
│   └── git_hooks/
├── rails-8.0/
│   ├── manifest.yml              # inherits_from: rails-8.1
│   └── ...                       # Only overrides
├── rails-7.1/
│   ├── manifest.yml              # inherits_from: rails-8.0
│   └── ...                       # Only overrides
└── shared/
    └── partials/
        ├── _ruby_install.erb
        └── _postgres_setup.erb
```

## Inheritance Model

The **most recent Rails version is always the reference** (source of truth). Older versions inherit and override only what differs.

### Current Hierarchy

```
rails-7.1 → rails-8.0 → rails-8.1 (reference)
                             ↑
                          shared/
```

### Adding a New Rails Version (e.g., 9.0)

**Before:**
```
rails-7.1 → rails-8.0 → rails-8.1 (reference)
```

**After:**
```
rails-7.1 → rails-8.0 → rails-8.1 → rails-9.0 (new reference)
```

**Process:**
1. Create `templates/rails-9.0/` with new reference templates
2. Update `templates/rails-8.1/manifest.yml` to inherit from `rails-9.0`
3. Keep only overrides in `rails-8.1/`
4. Update CLI defaults

### Version Support Policy

| Category | Versions | Notes |
|----------|----------|-------|
| **New projects (`new`)** | Latest only (currently 8.1) | Simplifies maintenance |
| **Sync (`sync`)** | 7.1 → latest | Support existing projects |
| **Lower bound** | Rails 7.1 | Unlikely to go below |

## Manifest Structure

```yaml
# templates/rails-8.0/manifest.yml
inherits_from: rails-8.1

variables:
  default_ruby_version: "4"
  solid_queue: false              # Not default in 8.0

overrides:
  - docker/Dockerfile.prod.erb    # Only override what differs
  - docker/compose.yml.erb
```

## Inheritance Rules

| Element | Behavior |
|---------|----------|
| **Templates not in `overrides`** | Inherited from parent |
| **Templates listed in `overrides`** | Local version used |
| **Variables** | Merged (child overrides parent) |
| **Partials (`shared/partials/`)** | Available to all |

## Template Loader

```ruby
# lib/moduloproject/template_engine/loader.rb
module Moduloproject
  module TemplateEngine
    class Loader
      TEMPLATES_ROOT = File.expand_path("../../../templates", __dir__)

      def initialize(rails_version)
        @rails_version = rails_version
        @manifest = load_manifest
        @inheritance_chain = build_inheritance_chain
      end

      def load(template_path)
        # Find template in inheritance chain
        @inheritance_chain.each do |version|
          full_path = File.join(TEMPLATES_ROOT, "rails-#{version}", template_path)
          return File.read(full_path) if File.exist?(full_path)
        end

        # Fallback to shared
        shared_path = File.join(TEMPLATES_ROOT, "shared", template_path)
        return File.read(shared_path) if File.exist?(shared_path)

        raise TemplateNotFound, "Template not found: #{template_path}"
      end

      def variables
        # Merge variables up the inheritance chain (child wins)
        @inheritance_chain.reverse.reduce({}) do |vars, version|
          manifest = load_manifest_for(version)
          vars.merge(manifest["variables"] || {})
        end
      end

      private

      def load_manifest
        load_manifest_for(@rails_version)
      end

      def load_manifest_for(version)
        path = File.join(TEMPLATES_ROOT, "rails-#{version}", "manifest.yml")
        return {} unless File.exist?(path)

        YAML.safe_load(File.read(path))
      end

      def build_inheritance_chain
        chain = [@rails_version]
        current = @manifest

        while current["inherits_from"]
          parent = current["inherits_from"].sub("rails-", "")
          chain << parent
          current = load_manifest_for(parent)
        end

        chain
      end
    end
  end
end
```

## Template Renderer

```ruby
# lib/moduloproject/template_engine/renderer.rb
module Moduloproject
  module TemplateEngine
    class Renderer
      def initialize(context)
        @context = context
      end

      def render(template_content)
        erb = ERB.new(template_content, trim_mode: "-")
        erb.result(binding_with_context)
      end

      private

      def binding_with_context
        # Create a binding with context variables accessible
        b = binding
        @context.each do |key, value|
          b.local_variable_set(key, value)
        end
        b
      end

      # Helper methods available in templates
      def partial(name)
        path = File.join(TemplateEngine::Loader::TEMPLATES_ROOT, "shared", "partials", "_#{name}.erb")
        content = File.read(path)
        render(content)
      end

      def mcp_enabled?(name)
        @context[:mcp]&.dig(name.to_s) || @context[:mcp]&.dig(name.to_sym)
      end

      def atlassian_site_name
        @context.dig(:mcp, :atlassian_site_name) || "modulotech"
      end
    end
  end
end
```

## Main Entry Point

```ruby
# lib/moduloproject/template_engine.rb
module Moduloproject
  module TemplateEngine
    class << self
      def load(template_path, context)
        loader = Loader.new(context[:rails_version])
        template_content = loader.load(template_path)

        # Merge loader variables with context
        full_context = loader.variables.merge(context)

        renderer = Renderer.new(full_context)
        renderer.render(template_content)
      end
    end

    class TemplateNotFound < StandardError; end
  end
end
```

## Deliverables

- [ ] Manifest YAML parser
- [ ] Inheritance chain builder
- [ ] Template loader with fallback
- [ ] ERB renderer with context
- [ ] Partial support
- [ ] Helper methods (mcp_enabled?, etc.)
- [ ] Templates for Rails 8.1 (reference)
- [ ] Templates for Rails 8.0 (overrides only)
- [ ] Templates for Rails 7.1 (overrides only)
- [ ] Unit tests for inheritance resolution
