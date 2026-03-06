# Phase 2 - Generators

**Status:** DONE

## Objectives

- [x] Base generator class with keepfile tracking
- [x] Docker generator
- [x] GitLab CI generator
- [x] Devcontainer generator
- [x] Git hooks generator
- [x] Config generator
- [x] Claude Code generator (comprehensive)
- [x] Generator registry with run_all

## What was built

### Structure

```
lib/moduloproject/
├── generators.rb              # Registry + runner (REGISTRY, run, run_all)
└── generators/
    ├── base.rb                # Abstract base with keepfile, write_file, copy_file, render_template
    ├── docker.rb              # Dockerfile.prod, compose, entrypoint, dockerignore
    ├── gitlab_ci.rb           # .gitlab-ci.yml, bin/ci, bin/test, config/ci.rb
    ├── devcontainer.rb        # .devcontainer/ (Dockerfile, compose, devcontainer.json)
    ├── git_hooks.rb           # bin/dc, bin/dcr, git hooks, .gitattributes, bin/refresh_generations
    ├── config.rb              # config/database.yml, cable.yml, deploy/*.yaml, puma.rb
    └── claude_code.rb         # Comprehensive Claude Code config (see Phase 7)
```

### Generator Registry

```ruby
REGISTRY = {
  docker: Docker,
  ci: GitlabCi,
  devcontainer: Devcontainer,
  hooks: GitHooks,
  claude: ClaudeCode,
  config: Config
}.freeze

DEFAULT_GENERATORS = %i[docker devcontainer config ci hooks claude].freeze
```

### Base Generator Features

- **Template rendering**: `render_template(path)` via `TemplateEngine`
- **Static file copy**: `copy_file(src, dest)` with template inheritance resolution
- **Keepfile tracking**: `.moduloproject.yml` stores generator versions to skip regeneration
- **Force mode**: `options[:force]` to overwrite existing files
- **Verbose logging**: `options[:verbose]` for file action logging
- **Executable files**: `options[:executable]` sets chmod 755

### Key difference from plan

The plan envisioned simple generators (2-3 files each). The actual implementation is richer:
- Docker generates Dockerfile.prod, compose.yml, entrypoint.sh, .dockerignore
- GitLab CI generates .gitlab-ci.yml, bin/ci, bin/test, config/ci.rb
- Git hooks generates bin/dc, bin/dcr, pre-merge-commit, post-rewrite, refresh_generations, .gitattributes
- Config generates database.yml, cable.yml, puma.rb, deploy/{production,staging,review}.yaml
- ClaudeCode generates 28+ files (hooks, rules, skills, agents, settings.json, CLAUDE.md, MCP server)
