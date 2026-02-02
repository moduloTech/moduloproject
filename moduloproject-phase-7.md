# Phase 7 - Claude Code

**Estimate:** 1 day

## Objectives

- MCP servers configuration templates
- CLAUDE.md generation
- Developer onboarding documentation

## Generated Files

```
.claude/
├── settings.json      # MCP servers and Claude Code settings
└── CLAUDE.md          # Project context for Claude Code
```

## MCP Servers Reference

### Package Summary

| MCP | Package | Type | Auth Method |
|-----|---------|------|-------------|
| **Datadog** | `@winor30/mcp-server-datadog` | Community | API Key + App Key |
| **GitLab** | Native (`/api/v4/mcp`) | Official (beta) | OAuth (browser) |
| **GitHub** | `@github/github-mcp-server` | Official | PAT |
| **Jira** | `@aashari/mcp-server-atlassian-jira` | Community | API Token |
| **Confluence** | `@aashari/mcp-server-atlassian-confluence` | Community | API Token |
| **Notion** | `@notionhq/notion-mcp-server` | Official | Integration Token |

### Baseline (always included)

| MCP Server | Purpose | Auth |
|------------|---------|------|
| **Datadog** | Logs, APM, metrics, incidents, monitors | `DATADOG_API_KEY`, `DATADOG_APP_KEY` |
| **GitLab** | Source integration (MRs, issues, pipelines) | OAuth (browser) |

### Optional (on-demand)

| MCP Server | Purpose | Required Env Variables |
|------------|---------|------------------------|
| **GitHub** | Public gems, external repos | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| **Jira** | Ticket management | `ATLASSIAN_SITE_NAME`, `ATLASSIAN_USER_EMAIL`, `ATLASSIAN_API_TOKEN` |
| **Confluence** | Wiki and documentation | Same as Jira |
| **Notion** | Internal documentation | `NOTION_API_KEY` |

## Configuration in .moduloproject.yml

```yaml
# MCP servers configuration
mcp:
  # Baseline - always included
  datadog: true
  gitlab: true

  # Optional - enable on-demand
  github: false
  jira: false
  confluence: false
  notion: false

  # Atlassian configuration (when jira or confluence enabled)
  atlassian_site_name: "modulotech"  # for modulotech.atlassian.net
```

## Template: settings.json.erb

```erb
{
  "mcpServers": {
    <%# Baseline: Datadog %>
    <% if mcp_enabled?(:datadog) %>
    "datadog": {
      "command": "npx",
      "args": ["-y", "@winor30/mcp-server-datadog"],
      "env": {
        "DATADOG_SITE": "datadoghq.eu"
      }
    },
    <% end %>

    <%# Baseline: GitLab (Native MCP - HTTP transport) %>
    <% if mcp_enabled?(:gitlab) %>
    "gitlab": {
      "type": "http",
      "url": "https://source.modulotech.fr/api/v4/mcp"
    },
    <% end %>

    <%# Optional: GitHub %>
    <% if mcp_enabled?(:github) %>
    "github": {
      "command": "npx",
      "args": ["-y", "@github/github-mcp-server"],
      "env": {}
    },
    <% end %>

    <%# Optional: Jira %>
    <% if mcp_enabled?(:jira) %>
    "jira": {
      "command": "npx",
      "args": ["-y", "@aashari/mcp-server-atlassian-jira"],
      "env": {
        "ATLASSIAN_SITE_NAME": "<%= atlassian_site_name %>"
      }
    },
    <% end %>

    <%# Optional: Confluence %>
    <% if mcp_enabled?(:confluence) %>
    "confluence": {
      "command": "npx",
      "args": ["-y", "@aashari/mcp-server-atlassian-confluence"],
      "env": {
        "ATLASSIAN_SITE_NAME": "<%= atlassian_site_name %>"
      }
    },
    <% end %>

    <%# Optional: Notion %>
    <% if mcp_enabled?(:notion) %>
    "notion": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"]
    },
    <% end %>

    "___end___": null
  }
}
```

## Template: CLAUDE.md.erb

```erb
# <%= project_name %>

## Project Overview

Rails <%= rails_version %> application using Ruby <%= ruby_version %>.

## Tech Stack

- **Database**: <%= database %>
- **Background Jobs**: Sidekiq + Redis
- **Frontend**: <%= frontend || 'Server-rendered views' %>
- **Asset Pipeline**: <%= js_bundler %>

## Development

```bash
# Start development environment
docker compose up

# Run tests
bin/dcr bin/rspec

# Run linter
bin/dcr bundle exec rubocop
```

## Datadog Integration

This project sends logs and metrics to Datadog. Use Claude Code's Datadog MCP to:
- Query application logs
- Analyze performance metrics
- Investigate errors and traces

## GitLab Integration

Use Claude Code's GitLab MCP to:
- View merge requests and issues
- Check pipeline status
- Browse repository
```

## Onboarding Documentation

Generated via `moduloproject init --with-onboarding`:

```markdown
# Developer Onboarding - Claude Code

## Required Environment Variables

Add these to your `~/.zshrc`:

### Datadog (required)
export DATADOG_API_KEY="your_api_key"
export DATADOG_APP_KEY="your_app_key"

Get keys from: https://app.datadoghq.eu → Organization Settings

Required scopes for App Key: `incidents_read`, `monitors_read`, `logs_read_data`, `metrics_read`, `dashboards_read`, `apm_read`

### GitLab (Source)
No configuration needed! GitLab MCP uses OAuth authentication.
On first use, your browser will open to authenticate with Source.

### GitHub (optional)
export GITHUB_PERSONAL_ACCESS_TOKEN="your_github_token"

Create token at: https://github.com/settings/tokens
Required scopes: `repo`, `read:org`

### Atlassian (Jira/Confluence)
export ATLASSIAN_USER_EMAIL="your.email@modulotech.fr"
export ATLASSIAN_API_TOKEN="your_atlassian_api_token"

Create token at: https://id.atlassian.com/manage-profile/security/api-tokens

### Notion
export NOTION_API_KEY="your_notion_integration_token"

Create integration at: https://www.notion.so/my-integrations

## Verify Setup

source ~/.zshrc
claude  # Open Claude Code in project directory

Ask Claude:
- "Show me recent error logs from Datadog"
- "What are the open MRs on this project?"
```

## CLI: Enable Optional MCP

```bash
# Enable Jira for a project
moduloproject config mcp.jira true
moduloproject config mcp.atlassian_site_name "modulotech"
moduloproject sync --only claude

# Check current MCP configuration
moduloproject config --list | grep mcp
```

## Per-Project Defaults

```yaml
# kaze/.moduloproject.yml
version: 1

mcp:
  jira: true
  atlassian_site_name: "modulotech"
```

Committed to repo → all developers get Jira MCP automatically.

## Deliverables

- [ ] settings.json.erb template with all MCP servers
- [ ] CLAUDE.md.erb template
- [ ] ONBOARDING.md.erb template
- [ ] `init --with-onboarding` option
- [ ] `config` command for MCP settings
- [ ] Helper methods: `mcp_enabled?`, `atlassian_site_name`
- [ ] Unit tests for template rendering
    