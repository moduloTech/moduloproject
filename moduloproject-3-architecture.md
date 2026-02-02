# Moduloproject 3.0 - Overview

## What is Moduloproject?

A standalone CLI tool distributed via **Homebrew** for generating new Rails projects and synchronizing existing projects with Modulotech infrastructure standards. No runtime dependency on Rails or Modulorails.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Language** | Ruby | Team expertise, ERB templating, ecosystem coherence |
| **Distribution** | Homebrew tap | Handles Ruby 4 dependency automatically, no reliance on macOS system Ruby |
| **Templates** | Embedded in gem | Simpler versioning, override via `.moduloproject.yml` possible |

## Scope

### In Scope

| Category | Components |
|----------|------------|
| **Project generation** | Full Rails project scaffolding with Modulotech standards |
| **Infrastructure sync** | Docker, CI/CD, devcontainer, git hooks |
| **Developer tooling** | Claude Code configuration, MCP servers setup |
| **Diff/merge** | Smart comparison with sanctuary zone preservation |
| **Multi-version support** | Templates for Rails 7.1, 8.0, 8.1 |
| **GitLab integration** | Branch creation, MR creation via API |

### Out of Scope (handled by Modulorails)

- Ruby code abstractions (BaseService, SuccessData, ErrorData)
- Health checks implementation
- Intranet registration
- Remote Rubocop configuration fetching

## Installation

```bash
brew tap modulotech/tap
brew install moduloproject
```

## CLI Interface

```bash
moduloproject new <project-name> [options]   # Generate a new project
moduloproject sync [options]                  # Sync existing project
moduloproject diff                            # Show diff without applying
moduloproject init                            # Initialize .moduloproject.yml
moduloproject templates                       # List available template versions
```

## Implementation Phases

| Phase | Document | Estimate |
|-------|----------|----------|
| **1. Setup** | `phase-1-setup.md` | 2 days |
| **2. Generators** | `phase-2-generators.md` | 3 days |
| **3. Templates** | `phase-3-templates.md` | 2 days |
| **4. Command `new`** | `phase-4-new.md` | 2 days |
| **5. Command `sync`** | `phase-5-sync.md` | 3 days |
| **6. Sanctuary** | `phase-6-sanctuary.md` | 2 days |
| **7. Claude Code** | `phase-7-claude.md` | 1 day |
| **8. Tests** | `phase-8-tests.md` | 2 days |
| **9. Documentation** | `phase-9-docs.md` | 1 day |

**Total: ~18 days**

## Migration from Modulorails

These generators move from Modulorails to Moduloproject:

| Generator | Modulorails class | Notes |
|-----------|-------------------|-------|
| Docker | `Modulorails::DockerGenerator` | Remove Rails::Generators dependency |
| GitLab CI | `Modulorails::GitlabciGenerator` | Remove Rails::Generators dependency |
| Git hooks | `Modulorails::GitHooksGenerator` | Remove Rails::Generators dependency |
| Devcontainer | `Modulorails::DevcontainerGenerator` | Remove Rails::Generators dependency |
| Claude Code | `Modulorails::ClaudeCodeGenerator` | Enhanced with MCP configuration |

Modulorails 2.0 removes these generators and their automatic execution at boot.
