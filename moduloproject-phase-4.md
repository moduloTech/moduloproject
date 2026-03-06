# Phase 4 - Command `new`

**Status:** DONE

## Objectives

- [x] Port current Bash logic to Ruby
- [x] Project scaffolding via Docker-based Rails generation
- [x] Backend configuration (Active Job, Action Cable, Rails Cache)
- [x] Frontend setup (Vue/Vite, Hotwire/Importmap)
- [x] Ticketing configuration (GitLab, Jira, Roadmap)
- [x] Brakeman security scanning setup
- [x] Full integration tests

## CLI Interface

```bash
moduloproject new my-app \
  --ruby 3.4 \
  --rails 8.1 \
  --database postgresql \
  --frontend vue \
  --active-job sidekiq \
  --action-cable redis \
  --rails-cache redis \
  --ticket-provider gitlab \
  --gitlab-project group/project
```

| Option | Default | Values |
|--------|---------|--------|
| `--ruby` | Resolved from recipe | 3.1, 3.2, 3.3, 3.4 |
| `--rails` | 8.1 (latest) | 8.1, 8.0, 7.2 |
| `--database` | postgresql | postgresql, mysql2, sqlite3 |
| `--frontend` | vue | vue, hotwire |
| `--active-job` | Recipe default | sidekiq, solid_queue |
| `--action-cable` | Recipe default | redis, solid_cable |
| `--rails-cache` | Recipe default | redis, solid_cache |
| `--skip-docker` | false | - |
| `--ticket-provider` | Interactive/none | gitlab, jira, roadmap, none |
| `--gitlab-project` | - | GitLab project path |
| `--gitlab-host` | gitlab.com | GitLab hostname |
| `--jira-url` | - | Jira instance URL |
| `--jira-project` | - | Jira project key |
| `--jira-email` | - | Jira API email |
| `--roadmap-file` | ROADMAP.md | Roadmap file path |

## Execution Pipeline (13 steps)

```ruby
steps = [
  -> { configure_ticketing },       # TicketingConfig.resolve (CLI > TTY > none)
  -> { create_project_directory },   # mkdir_p, check not exists
  -> { generate_rails_app },         # RailsGenerator (Docker-based)
  -> { setup_active_job },           # Sidekiq or Solid Queue
  -> { setup_action_cable },         # Redis or Solid Cable
  -> { setup_rails_cache },          # Redis or Solid Cache
  -> { cleanup_solid },              # Remove unused Solid gems
  -> { setup_modulorails },          # Add modulorails gem + initializer
  -> { setup_brakeman },             # Add brakeman gem
  -> { setup_vite },                 # Vite + Vue3 setup (if vue frontend)
  -> { generate_infrastructure },    # Generators.run_all (Docker, CI, Claude, etc.)
  -> { setup_git },                  # git init + initial commit
  -> { display_success }             # Success box with next steps
]
```

## Key Implementation Details

### Recipe System

Each Rails version has a recipe (`recipes/rails-X.Y.yml`) defining:
- Compatible Ruby versions
- Default backends (active_job, action_cable, rails_cache)
- Available backends per concern

### RailsGenerator

Generates Rails app via Docker:
- Builds Docker command with Rails options (`--database`, `--skip-test`, `--javascript`, `--css`)
- Runs `rails new` inside a Ruby Docker container
- Handles Bun/Node.js environment setup

### TicketingConfig

Hybrid resolution: CLI options > interactive TTY prompt > none (non-interactive).
Supports 4 providers: `gitlab`, `jira`, `roadmap`, `none`.

### Backend Setup Classes

```
lib/moduloproject/setup/
├── active_job_setup.rb       # Delegates to Backends::ActiveJob
├── action_cable_setup.rb     # Delegates to Backends::ActionCable
├── rails_cache_setup.rb      # Delegates to Backends::RailsCache
├── brakeman_setup.rb         # Adds brakeman gem to Gemfile
└── solid_cleanup.rb          # Removes unused solid_* gems
```

### Validation

- Project name: `/\A[a-z][a-z0-9_-]*\z/`
- Rails version: Must exist in recipes
- Ruby version: Must be compatible per recipe
- Database: postgresql, mysql2, sqlite3
- Frontend: vue, hotwire
- Backends: Validated against recipe's available_backends_for()

## Test Coverage

- Unit tests: `spec/moduloproject/commands/new_spec.rb`
- Integration tests: `spec/integration/` with matrix of combinations
  - Rails: 8.1, 8.0, 7.2
  - Ruby: 3.1–3.4
  - Databases: postgresql, mysql2, sqlite3
  - Frontends: vue, hotwire
  - Backends: sidekiq, solid_queue, redis, solid_cable, solid_cache
- 535 examples, 0 failures, 99.37% line coverage
