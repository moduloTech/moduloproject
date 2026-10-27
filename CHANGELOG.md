# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Phase 4: `new` command** - Create new Rails projects with Modulotech conventions
  - Docker-based Rails generation (no local Ruby/Rails required)
  - Modulorails gem auto-configuration
  - Infrastructure generation (Docker, CI, devcontainer, git hooks, Claude Code)
  - Git repository initialization
  - CLI options: `--ruby`, `--rails`, `--database`, `--stack` (vue/hotwire), `--skip-docker`
  - Input validation with friendly error messages

## [3.0.1] - 2026-10-27

### Fixed

- Podman support: the container engine is `CONTAINER_ENGINE` if set, else Docker when its daemon answers, else Podman
- Image names are fully qualified (`docker.io/library/ruby:…`), so Podman no longer depends on short-name resolution
- Generated files are no longer chowned under rootless Podman, which already maps the container's root to the current
  user (the chown handed them to a subordinate uid)

## [3.0.0] - 2025-02-02

### Added

- Complete rewrite as a Ruby gem (replacing bash script)
- Thor-based CLI with subcommands: `version`, `new`, `sync`, `diff`, `init`, `templates`
- Automatic version check with 24h cache (checks RubyGems for updates)
- TTY-based UI with colored output and boxes
- Homebrew distribution support

### Changed

- Minimum Ruby version is now 3.2.0
- Project structure follows standard Ruby gem conventions

### Removed

- Legacy bash script (preserved as `moduloproject-legacy.sh` for reference)

## [2.0.0] - Previous

- Original bash script implementation
