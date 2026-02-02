# Phase 1 - Setup

**Estimate:** 2 days

## Objectives

- Create gem structure
- CLI skeleton with Thor
- Homebrew tap setup
- Version check mechanism

## Project Structure

```
moduloproject/
├── lib/
│   ├── moduloproject.rb
│   └── moduloproject/
│       ├── version.rb
│       └── cli.rb                    # Thor-based CLI
├── exe/
│   └── moduloproject
├── spec/
├── Gemfile
├── moduloproject.gemspec
├── README.md
└── CHANGELOG.md
```

## Dependencies

```ruby
# moduloproject.gemspec
spec.required_ruby_version = ">= 3.2.0"

spec.add_dependency "thor", "~> 1.3"           # CLI framework
spec.add_dependency "tty-prompt", "~> 0.23"    # Interactive prompts
spec.add_dependency "tty-box", "~> 0.7"        # Boxes for notifications
spec.add_dependency "diffy", "~> 3.4"          # Diff generation
spec.add_dependency "gitlab", "~> 4.0"         # GitLab API
```

## Homebrew Distribution

### Formula

```ruby
# homebrew-tap/Formula/moduloproject.rb
class Moduloproject < Formula
  desc "CLI for Modulotech Rails project generation and synchronization"
  homepage "https://github.com/moduloTech/moduloproject"
  url "https://github.com/moduloTech/moduloproject/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "ruby@4"

  def install
    ENV["GEM_HOME"] = libexec
    ENV["GEM_PATH"] = libexec
    system "gem", "build", "moduloproject.gemspec"
    system "gem", "install", "--no-document", "moduloproject-#{version}.gem"
    bin.install libexec/"bin/moduloproject"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"], GEM_PATH: ENV["GEM_PATH"])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/moduloproject --version")
  end
end
```

### Repository Structure

```
GitHub (modulotech)
├── moduloproject/           # Source code (public)
└── homebrew-tap/            # Homebrew formulas (public)
    └── Formula/
        └── moduloproject.rb
```

## Version Check

### Behavior

```bash
$ moduloproject sync

╭─────────────────────────────────────────────────────────────╮
│  A new version of moduloproject is available: 3.1.0         │
│  You are running: 3.0.0                                     │
│                                                             │
│  Update with: brew upgrade moduloproject                    │
╰─────────────────────────────────────────────────────────────╯

Detected: Ruby 4, Rails 8.1, postgresql
...
```

### Implementation

```ruby
# lib/moduloproject/version_check.rb
module Moduloproject
  class VersionCheck
    CACHE_FILE = File.expand_path("~/.moduloproject/version_cache.json")
    CACHE_TTL = 86400  # 24 hours
    RUBYGEMS_API = "https://rubygems.org/api/v1/versions/moduloproject/latest.json"

    def self.check_and_notify
      new.check_and_notify
    end

    def check_and_notify
      return if skip_check?

      latest = fetch_latest_version
      return unless latest
      return if Gem::Version.new(latest) <= Gem::Version.new(Moduloproject::VERSION)

      display_update_notice(latest)
    end

    private

    def skip_check?
      ENV["MODULOPROJECT_SKIP_VERSION_CHECK"] == "1" ||
        !$stdout.tty?  # Skip in CI/non-interactive
    end

    def fetch_latest_version
      return cached_version if cache_valid?

      require "net/http"
      require "json"

      uri = URI(RUBYGEMS_API)
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      version = data["version"]

      write_cache(version)
      version
    rescue StandardError
      nil  # Fail silently, don't block user
    end

    def cache_valid?
      return false unless File.exist?(CACHE_FILE)

      data = JSON.parse(File.read(CACHE_FILE))
      Time.now.to_i - data["checked_at"] < CACHE_TTL
    rescue StandardError
      false
    end

    def cached_version
      JSON.parse(File.read(CACHE_FILE))["version"]
    rescue StandardError
      nil
    end

    def write_cache(version)
      FileUtils.mkdir_p(File.dirname(CACHE_FILE))
      File.write(CACHE_FILE, JSON.generate(version: version, checked_at: Time.now.to_i))
    end

    def display_update_notice(latest)
      puts TTY::Box.frame(
        "A new version of moduloproject is available: #{latest}",
        "You are running: #{Moduloproject::VERSION}",
        "",
        "Update with: brew upgrade moduloproject",
        padding: 1,
        border: :round
      )
      puts
    end
  end
end
```

### CLI Integration

```ruby
# lib/moduloproject/cli.rb
module Moduloproject
  class CLI < Thor
    def self.start(args = ARGV, config = {})
      VersionCheck.check_and_notify
      super
    end

    desc "version", "Show version"
    def version
      puts Moduloproject::VERSION
    end

    # Placeholder commands for later phases
    desc "new NAME", "Generate a new Rails project"
    def new(name)
      puts "Not implemented yet"
    end

    desc "sync", "Synchronize project with latest standards"
    def sync
      puts "Not implemented yet"
    end
  end
end
```

### Environment Variables

| Variable | Effect |
|----------|--------|
| `MODULOPROJECT_SKIP_VERSION_CHECK=1` | Disable update check |

Version check is automatically skipped in non-TTY environments (CI pipelines).

## Release Process

1. Tag version in moduloproject repo: `git tag v3.0.0`
2. CI builds gem and pushes to RubyGems
3. CI computes SHA256 of release tarball
4. CI updates homebrew-tap formula with new version and SHA
5. Users run `brew upgrade moduloproject`

## Deliverables

- [ ] Gem skeleton with version.rb
- [ ] Thor CLI with `--version` and placeholder commands
- [ ] VersionCheck class
- [ ] Homebrew tap repository created
- [ ] Formula for moduloproject
- [ ] CI pipeline for gem release
