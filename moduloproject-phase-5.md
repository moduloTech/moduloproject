# Phase 5 - Command `sync`

**Status:** TODO

## Objectives

- [ ] Auto-detect project context (ProjectDetector)
- [ ] Diff generation between current files and templates
- [ ] Interactive, branch, and MR modes
- [ ] Component filtering (`--only docker,ci,claude`)
- [ ] Sanctuary zone preservation (see Phase 6)

## CLI Interface

```bash
# Interactive mode (default)
moduloproject sync

# Dry run - preview changes
moduloproject sync --dry-run

# Force overwrite without confirmation
moduloproject sync --force

# Sync specific components only
moduloproject sync --only docker,ci,claude
```

| Option | Default | Description |
|--------|---------|-------------|
| `--dry-run` | false | Preview changes without applying |
| `--force` | false | Apply changes without confirmation |
| `--only` | all | Comma-separated component list |

## Sync Components

| Component | Files |
|-----------|-------|
| `docker` | `Dockerfile.prod`, `compose.yml`, `entrypoint.sh`, `.dockerignore` |
| `ci` | `.gitlab-ci.yml`, `bin/ci`, `bin/test`, `config/ci.rb` |
| `devcontainer` | `.devcontainer/` (Dockerfile, compose.yml, devcontainer.json) |
| `claude` | `.claude/` (settings.json, CLAUDE.md, hooks, rules, skills, agents) |
| `hooks` | `bin/dc`, `bin/dcr`, git hooks, `.gitattributes` |
| `config` | `config/database.yml`, `cable.yml`, `puma.rb`, `deploy/` |
| `all` | All components (default) |

## Workflow

```
1. Detect project context (Ruby, Rails, database, frontend from project files)
2. Load appropriate templates via inheritance chain
3. Read sanctuary configuration (.moduloproject.yml + inline markers)
4. Generate diff for each component (render template vs current file)
5. Apply changes (interactive prompt per file, or force-apply)
```

## Implementation Plan

### ProjectDetector

Detects project configuration from existing files:
- Ruby version: `.ruby-version`
- Rails version: `Gemfile.lock`
- Database: `config/database.yml`
- Frontend: `package.json` (vue), `config/importmap.rb` (hotwire)
- JS engine: `vite.config.ts` / `config/importmap.rb`

### DiffGenerator

For each component file:
1. Render template with detected context
2. Read current file content
3. Preserve sanctuary zones (see Phase 6)
4. Compute diff using `Diffy` gem

### Interactive Mode

Uses `TTY::Prompt` per file:
- Yes — apply change
- No — skip
- Skip all — stop

### Reuse of existing infrastructure

The `Generators` registry and `TemplateEngine` are already fully functional.
Sync reuses the same generators but in "update" mode instead of "create" mode.
The keepfile (`.moduloproject.yml`) already tracks generator versions.

## Dependencies on Phase 6

Sanctuary zones (preserve custom user changes) are a Phase 6 feature.
A first version of sync can work without sanctuary support (overwrite or skip).
