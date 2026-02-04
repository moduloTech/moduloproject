---
name: integration-tests
description: Documentation on end-to-end integration tests for the `new` command
---

# End-to-end integration tests

Integration tests verify that `moduloproject new` generates a complete and correct Rails project via Docker, for every possible combination of options.

## Matrix (528 combinations)

7 axes form the cartesian product:

| Axis | Values |
|------|--------|
| Rails | 7.2, 8.0, 8.1 |
| Ruby | 3.1-3.4 (7.2), 3.2-3.4 (8.0), 3.2-3.4+4 (8.1) |
| Database | postgresql, mysql2, sqlite3 |
| Frontend | vue, hotwire |
| Active Job | sidekiq, solid_queue |
| Action Cable | redis, solid_cable |
| Rails Cache | redis, solid_cache |

Valid Ruby versions per Rails are defined in `spec/integration/support/matrix.rb` (`RUBY_VERSIONS_FOR_RAILS`).

## Architecture

```
spec/integration/
  spec_helper.rb                      # RSpec config (no SimpleCov)
  support/
    matrix.rb                         # Combination struct + matrix generation
    docker_guard.rb                   # Skip if Docker unavailable
    project_workspace.rb              # Tmpdir management
    matchers/                         # 6 custom matchers (YAML, JSON, Ruby, shell, executable, gem)
  shared_examples/                    # 15 factored validation files
  combinations/                       # 528 generated files (1 per combination)
script/
  generate_integration_specs.rb       # Spec file generator
```

## Commands

```bash
# Generate all 528 spec files
bundle exec rake integration:generate

# Run a single combination
bundle exec rake integration:single[rails81_ruby4_postgresql_vue_sidekiq_redis_redis]

# Run all combinations for a Rails version
bundle exec rake integration:rails_version[8.1]

# Run everything sequentially
bundle exec rake integration:test

# Run in parallel (N workers, default: CPU count)
bundle exec rake integration:parallel[4]

# Clean up temporary workspaces
bundle exec rake integration:clean
```

## Prerequisites

- **Docker** must be available (`docker info`). Tests are automatically skipped if absent.
- **Disk space**: ~40 MB per project. Peak = nb_workers x 40 MB (immediate cleanup after each combination).
- **Pre-pull images** in CI: `docker pull ruby:3.4-alpine && docker pull ruby:4-alpine`

## Isolation

- Integration tests are **excluded** from `bundle exec rspec` (via `.rspec` and `Rakefile`).
- No SimpleCov: they do not count toward coverage.
- Workspaces in `/private/tmp/moduloproject_integration` (macOS) or `$TMPDIR/moduloproject_integration` (Linux).

## Modifying the matrix

1. Edit `spec/integration/support/matrix.rb` (constants + `Combination` struct)
2. Regenerate: `bundle exec rake integration:generate`

## Adding a shared example

1. Create `spec/integration/shared_examples/my_example.rb`
2. Add it to `SHARED_EXAMPLES` in `script/generate_integration_specs.rb`
3. Regenerate: `bundle exec rake integration:generate`
