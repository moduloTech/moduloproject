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
