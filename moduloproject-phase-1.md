# Phase 1 - Setup

**Status:** DONE

## Objectives

- [x] Create gem structure
- [x] CLI skeleton with Thor
- [x] Version check mechanism
- [ ] Homebrew tap setup (post-release)

## What was built

### Project Structure

```
moduloproject/
├── lib/
│   ├── moduloproject.rb              # Autoload hub
│   └── moduloproject/
│       ├── version.rb                # VERSION = '3.0.0'
│       ├── cli.rb                    # Thor CLI (new, sync, diff, init, templates)
│       ├── version_check.rb          # RubyGems version check with 24h cache
│       ├── context.rb                # Project context data object
│       ├── recipe.rb                 # Rails version recipes with inheritance
│       ├── ticketing_config.rb       # Ticketing provider configuration
│       └── ...
├── exe/
│   └── moduloproject
├── spec/
├── Gemfile
├── moduloproject.gemspec
├── README.md
└── CHANGELOG.md
```

### Dependencies (gemspec)

```ruby
spec.required_ruby_version = ">= 3.2.0"

spec.add_dependency "thor", "~> 1.3"
spec.add_dependency "tty-prompt", "~> 0.23"
spec.add_dependency "tty-box", "~> 0.7"
```

### Version Check

- `VersionCheck` class with 24h TTL cache at `~/.moduloproject/version_cache.json`
- Checks RubyGems API for latest version
- Skip via `MODULOPROJECT_SKIP_VERSION_CHECK=1` or non-TTY environments
- Integrated in `CLI.start` before dispatching commands

### CLI Commands

- `moduloproject version` / `-v` / `--version` — Display version
- `moduloproject new APP_NAME [options]` — Fully implemented
- `moduloproject sync` — Stub (not implemented yet)
- `moduloproject diff` — Stub (not implemented yet)
- `moduloproject init` — Stub (not implemented yet)
- `moduloproject templates` — Stub (not implemented yet)

### Homebrew Distribution

Planned for post-release. Formula template exists in planning docs.

## Remaining

- Homebrew tap repository + formula (post-release)
- CI pipeline for gem release (post-release)
