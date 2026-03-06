# Phase 3 - Templates

**Status:** DONE

## Objectives

- [x] Template loader with inheritance chain
- [x] ERB renderer with context binding
- [x] Template inheritance system
- [x] Manifest-based version configuration

## What was built

### Structure

```
lib/moduloproject/
├── template_engine.rb                    # Facade (load, resolve_static_path)
└── template_engine/
    ├── loader.rb                         # Path resolution through inheritance chain
    ├── renderer.rb                       # ERB rendering with TemplateBinding
    ├── manifest.rb                       # YAML manifest parser
    └── inheritance_chain.rb              # Version chain builder

templates/
├── rails-8.1/                            # Reference version (source of truth)
│   ├── manifest.yml
│   ├── docker/                           # Dockerfile.prod.erb, entrypoint.sh.erb, etc.
│   ├── ci/                               # .gitlab-ci.yml.erb, bin_ci.rb.erb, etc.
│   ├── config/                           # database.yml.erb, cable.yml.erb, puma.rb.erb, deploy/
│   ├── claude/                           # CLAUDE.md.erb, settings.json.erb
│   ├── devcontainer/                     # Dockerfile.erb, compose.yml.erb, devcontainer.json.erb
│   └── git_hooks/                        # dc.sh.erb, dcr.sh.erb, pre-merge-commit.sh.erb, etc.
├── rails-8.0/
│   └── manifest.yml                      # inherits_from: rails-8.1
├── rails-7.2/
│   └── manifest.yml                      # inherits_from: rails-8.0
└── shared/
    ├── partials/                          # _ruby_install.erb, _database_packages.erb
    └── claude/                            # 28+ static files (hooks, rules, skills, agents, mcp)
```

### Inheritance Model

```
rails-7.2 → rails-8.0 → rails-8.1 (reference)
                             ↑
                          shared/
```

Template resolution: search current version → walk inheritance chain → fallback to `shared/`.

### Context & Template Binding

Context is a data object (`Context` class) with `ATTRIBUTE_KEYS`:

```ruby
ATTRIBUTE_KEYS = %i[
  project_root project_name ruby_version rails_version bundler_version
  adapter js_engine frontend image_name environment_name
  production_url staging_url review_base_url uses_redis
  test_command default_branch active_job_backend
].freeze
```

`TemplateBinding` exposes all context attributes plus helper methods (`postgresql?`, `mysql?`, `sqlite?`, `vue?`, `hotwire?`, `vite?`, `importmap?`) to ERB templates.

### Key differences from plan

- `TemplateBinding` class instead of binding-with-context approach
- `InheritanceChain` is a separate class
- `resolve_static_path` for non-ERB files (used by `copy_file`)
- Shared partials via `_partial_name.erb` convention
- Recipe system handles version-specific defaults (default Ruby, available backends)
