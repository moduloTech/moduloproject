# Phase 5 - Command `sync`

**Estimate:** 3 days

## Objectives

- Auto-detect project context
- Diff generation
- Interactive, branch, and MR modes
- Component filtering

## CLI Interface

```bash
# Interactive mode (default)
moduloproject sync

# Dry run - preview changes
moduloproject sync --dry-run

# Create a Git branch with changes
moduloproject sync --branch

# Create GitLab MR directly
GITLAB_TOKEN=xxx moduloproject sync --merge-request

# Sync specific components only
moduloproject sync --only docker,ci,claude

# Force overwrite sanctuary zones
moduloproject sync --force
```

## Sync Components

| Component | Files |
|-----------|-------|
| `docker` | `Dockerfile.prod`, `compose.yml`, `compose.override.yml` |
| `ci` | `.gitlab-ci.yml` |
| `devcontainer` | `.devcontainer/devcontainer.json` |
| `claude` | `.claude/settings.json`, `.claude/CLAUDE.md` |
| `hooks` | `.git/hooks/*` |
| `all` | All components (default) |

## Sync Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    moduloproject sync                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Detect project context                                  │
│     - Ruby version (from .ruby-version)                     │
│     - Rails version (from Gemfile.lock)                     │
│     - Database (from config/database.yml)                   │
│     - JS bundler (vite.config.js, importmap.rb)             │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Load appropriate templates                              │
│     - Match Rails version to template set                   │
│     - Apply template inheritance chain                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Read sanctuary configuration                            │
│     - Parse .moduloproject.yml                              │
│     - Scan files for inline markers                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Generate diff for each component                        │
│     - Render template with project context                  │
│     - Compare with current file                             │
│     - Preserve sanctuary zones in new content               │
│     - Detect conflicts                                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Apply changes                                           │
│     - Interactive: prompt for each file                     │
│     - Branch: create Git branch, commit all                 │
│     - MR: push branch, create GitLab merge request          │
└─────────────────────────────────────────────────────────────┘
```

## Project Detector

```ruby
# lib/moduloproject/project_detector.rb
module Moduloproject
  class ProjectDetector
    def initialize(project_root = Dir.pwd)
      @root = project_root
    end

    def detect
      {
        project_name: detect_project_name,
        project_root: @root,
        ruby_version: detect_ruby_version,
        rails_version: detect_rails_version,
        database: detect_database,
        js_bundler: detect_js_bundler,
        frontend: detect_frontend
      }
    end

    private

    def detect_project_name
      File.basename(@root)
    end

    def detect_ruby_version
      ruby_version_file = File.join(@root, ".ruby-version")
      return File.read(ruby_version_file).strip if File.exist?(ruby_version_file)
      "4"
    end

    def detect_rails_version
      lockfile = File.join(@root, "Gemfile.lock")
      return nil unless File.exist?(lockfile)

      content = File.read(lockfile)
      match = content.match(/rails \((\d+\.\d+)/)
      match ? match[1] : nil
    end

    def detect_database
      database_yml = File.join(@root, "config", "database.yml")
      return "postgresql" unless File.exist?(database_yml)

      content = File.read(database_yml)
      return "mysql" if content.include?("mysql")
      "postgresql"
    end

    def detect_js_bundler
      return "vite" if File.exist?(File.join(@root, "vite.config.js"))
      return "vite" if File.exist?(File.join(@root, "vite.config.ts"))
      return "importmap" if File.exist?(File.join(@root, "config", "importmap.rb"))
      "vite"
    end

    def detect_frontend
      package_json = File.join(@root, "package.json")
      return nil unless File.exist?(package_json)

      content = File.read(package_json)
      return "vue3" if content.include?('"vue"')
      nil
    end
  end
end
```

## Sync Command

```ruby
# lib/moduloproject/commands/sync.rb
module Moduloproject
  module Commands
    class Sync
      COMPONENTS = %w[docker ci devcontainer claude hooks].freeze

      def initialize(options = {})
        @options = options
        @components = parse_components(options[:only])
        @mode = determine_mode(options)
      end

      def execute
        context = detect_context
        config = load_configuration
        
        puts "Detected: Ruby #{context[:ruby_version]}, Rails #{context[:rails_version]}, #{context[:database]}"

        diffs = generate_diffs(context, config)
        
        if diffs.empty?
          puts "✓ Infrastructure is up to date"
          return
        end

        case @mode
        when :dry_run
          display_diffs(diffs)
        when :interactive
          apply_interactively(diffs)
        when :branch
          apply_to_branch(diffs)
        when :merge_request
          create_merge_request(diffs)
        end
      end

      private

      def parse_components(only)
        return COMPONENTS if only.nil? || only == "all"
        only.split(",").map(&:strip)
      end

      def determine_mode(options)
        return :dry_run if options[:dry_run]
        return :branch if options[:branch]
        return :merge_request if options[:merge_request]
        :interactive
      end

      def detect_context
        detector = ProjectDetector.new
        context = detector.detect
        
        # Merge with .moduloproject.yml overrides
        config = load_configuration
        context.merge(config.fetch(:context, {}))
        context[:mcp] = config.fetch(:mcp, default_mcp_config)
        context
      end

      def load_configuration
        Configuration.load
      end

      def generate_diffs(context, config)
        diffs = []

        @components.each do |component|
          component_diffs = DiffGenerator.new(component, context, config).generate
          diffs.concat(component_diffs)
        end

        diffs.reject { |d| d[:old] == d[:new] }
      end

      def display_diffs(diffs)
        diffs.each do |diff|
          puts "\n#{diff[:file]}:"
          puts Diffy::Diff.new(diff[:old], diff[:new]).to_s(:color)
        end
      end

      def apply_interactively(diffs)
        prompt = TTY::Prompt.new

        diffs.each do |diff|
          puts "\n#{diff[:file]}:"
          puts Diffy::Diff.new(diff[:old], diff[:new]).to_s(:color)

          choice = prompt.select("Apply this change?") do |menu|
            menu.choice "Yes", :yes
            menu.choice "No", :no
            menu.choice "Edit", :edit
            menu.choice "Skip all remaining", :skip_all
          end

          case choice
          when :yes
            File.write(diff[:path], diff[:new])
            puts "✓ Applied"
          when :edit
            edited = open_in_editor(diff[:new])
            File.write(diff[:path], edited)
            puts "✓ Applied (edited)"
          when :skip_all
            break
          end
        end
      end

      def apply_to_branch(diffs)
        branch_name = "moduloproject-sync-#{Time.now.strftime('%Y%m%d%H%M%S')}"
        
        system("git checkout -b #{branch_name}")
        
        diffs.each do |diff|
          File.write(diff[:path], diff[:new])
        end

        system("git add .")
        system("git commit -m 'chore: sync infrastructure via moduloproject'")
        
        puts "✓ Changes committed to branch: #{branch_name}"
      end

      def create_merge_request(diffs)
        apply_to_branch(diffs)
        
        # Push and create MR via GitLab API
        GitlabIntegration.new.create_merge_request(
          branch: current_branch,
          title: "chore: sync infrastructure via moduloproject",
          description: generate_mr_description(diffs)
        )
      end

      def default_mcp_config
        { datadog: true, gitlab: true }
      end
    end
  end
end
```

## Diff Generator

```ruby
# lib/moduloproject/diff_generator.rb
module Moduloproject
  class DiffGenerator
    COMPONENT_FILES = {
      "docker" => %w[Dockerfile.prod compose.yml compose.override.yml],
      "ci" => %w[.gitlab-ci.yml],
      "devcontainer" => %w[.devcontainer/devcontainer.json],
      "claude" => %w[.claude/settings.json .claude/CLAUDE.md],
      "hooks" => %w[.git/hooks/pre-commit .git/hooks/post-rewrite]
    }.freeze

    def initialize(component, context, config)
      @component = component
      @context = context
      @config = config
      @sanctuary = Sanctuary::Parser.new(config)
    end

    def generate
      files = COMPONENT_FILES[@component] || []
      
      files.map do |file|
        template_path = file_to_template(file)
        new_content = TemplateEngine.load(template_path, @context)
        
        current_path = File.join(@context[:project_root], file)
        old_content = File.exist?(current_path) ? File.read(current_path) : ""

        # Preserve sanctuary zones
        new_content = @sanctuary.preserve(file, old_content, new_content)

        {
          file: file,
          path: current_path,
          old: old_content,
          new: new_content
        }
      end
    end

    private

    def file_to_template(file)
      # Map file path to template path
      case file
      when /^\.git\/hooks\//
        "git_hooks/#{File.basename(file)}.erb"
      when /^\.devcontainer\//
        "devcontainer/#{File.basename(file)}.erb"
      when /^\.claude\//
        "claude/#{File.basename(file)}.erb"
      when ".gitlab-ci.yml"
        "ci/.gitlab-ci.yml.erb"
      else
        "docker/#{file}.erb"
      end
    end
  end
end
```

## CLI Integration

```ruby
# lib/moduloproject/cli.rb (addition)
desc "sync", "Synchronize project with latest standards"
option :dry_run, type: :boolean, default: false, desc: "Preview changes"
option :branch, type: :boolean, default: false, desc: "Create a Git branch"
option :merge_request, type: :boolean, default: false, desc: "Create GitLab MR"
option :only, type: :string, desc: "Components to sync (docker,ci,claude...)"
option :force, type: :boolean, default: false, desc: "Overwrite sanctuary zones"
def sync
  Commands::Sync.new(options.to_h.transform_keys(&:to_sym)).execute
end

desc "diff", "Show diff without applying changes"
option :output, type: :string, desc: "Output format (patch, patches/)"
option :quiet, type: :boolean, default: false, desc: "Quiet mode for CI"
def diff
  Commands::Sync.new(dry_run: true, quiet: options[:quiet]).execute
end
```

## Deliverables

- [ ] ProjectDetector class
- [ ] Commands::Sync class
- [ ] DiffGenerator class
- [ ] Interactive mode with TTY::Prompt
- [ ] Branch mode
- [ ] MR mode with GitLab API
- [ ] `--only` component filtering
- [ ] `diff` command with patch output
- [ ] Integration tests
