# Phases 8-9 - Tests & Documentation

## Phase 8 - Tests (2 days)

### Test Structure

```
spec/
├── spec_helper.rb
├── moduloproject/
│   ├── cli_spec.rb
│   ├── configuration_spec.rb
│   ├── project_detector_spec.rb
│   ├── version_check_spec.rb
│   ├── commands/
│   │   ├── new_spec.rb
│   │   └── sync_spec.rb
│   ├── generators/
│   │   ├── docker_spec.rb
│   │   ├── gitlab_ci_spec.rb
│   │   ├── devcontainer_spec.rb
│   │   ├── claude_code_spec.rb
│   │   └── git_hooks_spec.rb
│   ├── template_engine/
│   │   ├── loader_spec.rb
│   │   ├── renderer_spec.rb
│   │   └── inheritance_spec.rb
│   └── sanctuary/
│       ├── parser_spec.rb
│       ├── merger_spec.rb
│       └── conflict_resolver_spec.rb
└── integration/
    ├── new_project_spec.rb
    └── sync_project_spec.rb
```

### Critical Test Cases

#### Template Inheritance

```ruby
# spec/moduloproject/template_engine/inheritance_spec.rb
RSpec.describe Moduloproject::TemplateEngine::Loader do
  describe "#load" do
    context "with Rails 8.0 project" do
      let(:loader) { described_class.new("8.0") }

      it "loads overridden template from 8.0" do
        # Template exists in rails-8.0/
        content = loader.load("docker/compose.yml.erb")
        expect(content).to include("8.0 specific")
      end

      it "falls back to 8.1 for non-overridden templates" do
        # Template only exists in rails-8.1/
        content = loader.load("ci/.gitlab-ci.yml.erb")
        expect(content).to include("8.1 reference")
      end

      it "falls back to shared for partials" do
        content = loader.load("partials/_ruby_install.erb")
        expect(content).to be_present
      end
    end

    context "inheritance chain" do
      it "builds correct chain for 7.1" do
        loader = described_class.new("7.1")
        expect(loader.send(:build_inheritance_chain)).to eq(["7.1", "8.0", "8.1"])
      end
    end
  end

  describe "#variables" do
    it "merges variables with child overriding parent" do
      loader = described_class.new("8.0")
      vars = loader.variables
      
      expect(vars[:solid_queue]).to eq(false)  # 8.0 override
      expect(vars[:default_ruby_version]).to eq("4")  # inherited
    end
  end
end
```

#### Sanctuary Preservation

```ruby
# spec/moduloproject/sanctuary/parser_spec.rb
RSpec.describe Moduloproject::Sanctuary::Parser do
  describe "#extract_zones" do
    let(:config) { { preserve_markers: true, sanctuaries: [] } }
    let(:parser) { described_class.new(config) }

    context "with inline markers" do
      let(:content) do
        <<~YAML
          key: value
          # moduloproject:preserve:start
          custom:
            setting: true
          # moduloproject:preserve:end
          other: value
        YAML
      end

      it "extracts zone between markers" do
        zones = parser.extract_zones("test.yml", content)
        
        expect(zones.length).to eq(1)
        expect(zones.first[:content]).to include("custom:")
        expect(zones.first[:type]).to eq(:inline)
      end
    end

    context "with explicit sanctuaries" do
      let(:config) do
        {
          preserve_markers: false,
          sanctuaries: [
            { file: "test.yml", sections: ['"# START" .. "# END"'] }
          ]
        }
      end

      let(:content) do
        <<~YAML
          key: value
          # START
          preserved: content
          # END
          other: value
        YAML
      end

      it "extracts explicit sanctuary zones" do
        zones = parser.extract_zones("test.yml", content)
        
        expect(zones.length).to eq(1)
        expect(zones.first[:content]).to include("preserved:")
      end
    end
  end
end
```

#### Sync Command

```ruby
# spec/integration/sync_project_spec.rb
RSpec.describe "moduloproject sync", type: :integration do
  let(:project_dir) { Dir.mktmpdir }

  before do
    # Setup fake Rails project
    FileUtils.mkdir_p(File.join(project_dir, "config"))
    File.write(File.join(project_dir, ".ruby-version"), "4.0.0")
    File.write(File.join(project_dir, "Gemfile.lock"), "rails (8.1.0)")
  end

  after { FileUtils.rm_rf(project_dir) }

  it "detects project context correctly" do
    Dir.chdir(project_dir) do
      detector = Moduloproject::ProjectDetector.new
      context = detector.detect

      expect(context[:ruby_version]).to eq("4.0.0")
      expect(context[:rails_version]).to eq("8.1")
    end
  end

  it "generates infrastructure files" do
    Dir.chdir(project_dir) do
      Moduloproject::Commands::Sync.new(dry_run: false).execute

      expect(File.exist?("Dockerfile.prod")).to be true
      expect(File.exist?(".gitlab-ci.yml")).to be true
      expect(File.exist?(".claude/settings.json")).to be true
    end
  end

  it "preserves sanctuary zones" do
    # Create existing file with sanctuary
    gitlab_ci = <<~YAML
      include:
        - template: test.yml
      
      # moduloproject:preserve:start
      custom_job:
        script: ./custom.sh
      # moduloproject:preserve:end
    YAML
    File.write(File.join(project_dir, ".gitlab-ci.yml"), gitlab_ci)

    Dir.chdir(project_dir) do
      Moduloproject::Commands::Sync.new.execute

      new_content = File.read(".gitlab-ci.yml")
      expect(new_content).to include("custom_job:")
      expect(new_content).to include("./custom.sh")
    end
  end
end
```

### Deliverables Phase 8

- [ ] Unit tests for all classes
- [ ] Integration tests for `new` command
- [ ] Integration tests for `sync` command
- [ ] Test fixtures (fake projects, templates)
- [ ] CI pipeline running tests
- [ ] Coverage report (target: 80%+)

---

## Phase 9 - Documentation (1 day)

### README.md Structure

```markdown
# Moduloproject

CLI for Modulotech Rails project generation and infrastructure synchronization.

## Installation

brew tap modulotech/tap
brew install moduloproject

## Quick Start

# Create a new project
moduloproject new my-app

# Sync existing project
cd existing-project
moduloproject sync

## Commands

### new
### sync
### diff
### init
### config
### templates

## Configuration

### .moduloproject.yml
### Sanctuary Zones
### MCP Servers

## Template Inheritance

## Migration from Modulorails 1.x

## Contributing

## License
```

### Migration Guide

```markdown
# Migration from Modulorails 1.x

## Overview

Moduloproject 3.0 replaces the infrastructure generators previously in Modulorails.
Modulorails 2.0 focuses only on Ruby code (BaseService, health checks, etc.).

## Steps

### 1. Install Moduloproject

brew tap modulotech/tap
brew install moduloproject

### 2. Initialize Configuration

cd your-project
moduloproject init

### 3. Review Generated .moduloproject.yml

Edit to match your project's needs (MCP servers, sanctuaries, etc.)

### 4. First Sync

moduloproject sync --dry-run  # Preview changes
moduloproject sync            # Apply changes

### 5. Update Modulorails

# Gemfile
gem 'modulorails', '~> 2.0'

bundle update modulorails

### 6. Update Modulorails Initializer

See Modulorails 2.0 migration guide for configuration changes.

## What Moved Where

| Feature | Modulorails 1.x | Now |
|---------|-----------------|-----|
| Docker templates | Auto-generated at boot | `moduloproject sync` |
| GitLab CI | Auto-generated at boot | `moduloproject sync` |
| Git hooks | Auto-generated at boot | `moduloproject sync` |
| Devcontainer | Auto-generated at boot | `moduloproject sync` |
| Claude Code | Auto-generated at boot | `moduloproject sync` |
| BaseService | Modulorails | Modulorails 2.0 |
| Health checks | Modulorails | Modulorails 2.0 |
| Intranet registration | Modulorails | Modulorails 2.0 |
```

### CHANGELOG.md

```markdown
# Changelog

## [3.0.0] - 2026-XX-XX

### Added
- `new` command for project generation
- `sync` command for infrastructure synchronization
- `diff` command for previewing changes
- `init` command for configuration setup
- `config` command for MCP settings
- Template inheritance system (Rails 7.1 → 8.0 → 8.1)
- Sanctuary zones for preserving custom configurations
- MCP servers configuration (Datadog, GitLab, GitHub, Jira, Confluence, Notion)
- Homebrew distribution

### Changed
- Extracted from Modulorails (now standalone CLI)
- No longer requires Rails runtime

### Removed
- Dependency on Rails::Generators
```

### Deliverables Phase 9

- [ ] README.md with full documentation
- [ ] Migration guide from Modulorails 1.x
- [ ] CHANGELOG.md
- [ ] Inline code documentation (YARD)
- [ ] Examples directory with sample configurations
- [ ] Troubleshooting section
