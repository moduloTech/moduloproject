# Phase 7 - Claude Code

**Status:** DONE

## Objectives

- [x] Comprehensive Claude Code configuration generator
- [x] Hooks (pre-tool, post-tool)
- [x] Rules (git safety, conventions)
- [x] Skills (commit, migration, review, brainstorm, implement, etc.)
- [x] Agents (code-review-specialist, debug-specialist)
- [x] settings.json (permissions, hooks, env)
- [x] CLAUDE.md (project documentation)
- [x] Ticketing integration (MCP server + workflow skills)
- [x] Brakeman security scanning hook

## What was built

### Generated Files (~28 files)

```
.claude/
├── settings.json                          # Programmatic JSON (permissions, hooks, env)
├── hooks/
│   ├── prevent-destructive.sh             # PreToolUse: block dangerous commands
│   ├── prevent-git-push.sh                # PreToolUse: block git push
│   ├── post-edit-rubocop.sh               # PostToolUse: auto-lint Ruby
│   ├── post-edit-brakeman.sh              # PostToolUse: security scan
│   └── post-edit-eslint.sh                # PostToolUse: lint JS (vue only)
├── rules/
│   ├── git-safety.md                      # Git operation rules
│   ├── prevent-destructive.md             # Destructive command prevention
│   ├── ruby-conventions.md                # ERB: ruby/rails version-aware conventions
│   ├── javascript-conventions-vue.md      # Vue/Vite conventions (vue only)
│   └── javascript-conventions-stimulus.md # Stimulus/Hotwire conventions (hotwire only)
├── skills/
│   ├── commit/SKILL.md                    # Git commit workflow
│   ├── migration/SKILL.md                 # Rails migration patterns
│   ├── rails-practices/SKILL.md           # Rails best practices
│   ├── review-code/SKILL.md               # Code review checklist
│   ├── review-performance/SKILL.md        # Performance review
│   ├── review-security/SKILL.md           # Security review
│   ├── rspec-patterns/SKILL.md            # RSpec testing patterns
│   ├── vue-practices/SKILL.md             # Vue.js practices (vue only)
│   ├── vitest-patterns/SKILL.md           # Vitest testing (vue only)
│   ├── brainstorm/SKILL.md                # ERB: project-aware brainstorming (ticketing only)
│   ├── implement/SKILL.md                 # ERB: implementation workflow (ticketing only)
│   ├── review/SKILL.md                    # ERB: review workflow (ticketing only)
│   └── improve/SKILL.md                   # ERB: improvement workflow (ticketing only)
├── agents/
│   ├── code-review-specialist.md          # Code review agent
│   └── debug-specialist.md                # Debug agent
└── mcp-servers/
    └── ticket-ops/                        # MCP ticketing server (ticketing only)
        ├── index.mjs
        └── package.json
CLAUDE.md                                  # ERB: project documentation
.mcp.json                                  # MCP server config (ticketing only)
```

### Conditional Logic

| Component | Condition |
|-----------|-----------|
| `post-edit-eslint.sh` | `context.vue?` |
| `javascript-conventions-vue.md` | `context.vue?` |
| `vue-practices`, `vitest-patterns` | `context.vue?` |
| `javascript-conventions-stimulus.md` | `context.hotwire?` |
| 4 workflow skills + MCP server + .mcp.json | `ticketing_enabled?` |
| `glab` in permissions allow list | `ticketing_config&.gitlab?` |
| `post-edit-brakeman.sh` | Always (BrakemanSetup adds gem) |

### settings.json Construction

Built programmatically in Ruby (not ERB), because ticketing data comes from
`options[:ticketing]` (not from Context):

```ruby
{
  "env" => { "DISABLE_INSTALLATION_CHECKS" => "1" },
  "permissions" => {
    "allow" => [...],    # rspec, rubocop, rails, brakeman, git read, etc.
    "deny" => ["Bash(git push:*)"],
    "ask" => ["Bash(git add:*)", "Bash(git commit:*)"]
  },
  "hooks" => {
    "PreToolUse" => [{ "matcher" => "Bash", "hooks" => [...] }],
    "PostToolUse" => [{ "matcher" => "Edit|Write", "hooks" => [...] }]
  }
}
```

### .mcp.json Construction

Conditional per ticketing provider:
- **GitLab**: `TICKET_PROVIDER=gitlab`, `GITLAB_PROJECT`, `GITLAB_HOST`
- **Jira**: `TICKET_PROVIDER=jira`, `JIRA_URL`, `JIRA_PROJECT`, `JIRA_EMAIL`, `${JIRA_API_TOKEN}`
- **Roadmap**: `TICKET_PROVIDER=roadmap`, `ROADMAP_FILE`

### Generator Architecture

```ruby
module ClaudeCodeFileMaps
  HOOKS = { ... }           # 4 base hooks
  VUE_HOOKS = { ... }       # 1 eslint hook
  RULES = { ... }           # 2 static rules
  ERB_RULES = { ... }       # 1 ERB rule (ruby-conventions)
  VUE_RULES = { ... }       # 1 vue rule
  HOTWIRE_ERB_RULES = { ... } # 1 stimulus rule
  GENERIC_SKILLS = { ... }  # 7 generic skills
  VUE_SKILLS = { ... }      # 2 vue skills
  WORKFLOW_SKILLS = { ... }  # 4 workflow ERB skills
  AGENTS = { ... }          # 2 agents
  MCP_SERVER_FILES = { ... } # 2 MCP server files
end

class ClaudeCode < Base
  VERSION = 2
  FM = ClaudeCodeFileMaps
  # ...
end
```

### TicketingConfig

```ruby
class TicketingConfig
  PROVIDERS = %w[gitlab jira roadmap none].freeze

  def self.resolve(options)
    if options[:ticket_provider]    -> from_cli(options)
    elsif $stdin.tty?               -> from_prompt (TTY::Prompt)
    else                            -> new(provider: 'none')
  end
end
```

### BrakemanSetup

Adds `gem 'brakeman', require: false, group: :development` to Gemfile.
Follows the same pattern as `ModulorailsSetup`.

## Key differences from original plan

- Original Phase 7 was about MCP servers (Datadog, GitLab, GitHub, Jira, Confluence, Notion)
  using third-party npx packages. The implementation instead uses a custom ticket-ops MCP server
  with provider-specific env vars.
- The `settings.json.erb` template approach was replaced by programmatic JSON construction.
- Brakeman was added as a security scanning step integrated into the generator.
- The `CLAUDE.md` template is project-aware (includes Ruby/Rails version, database, Docker setup).
