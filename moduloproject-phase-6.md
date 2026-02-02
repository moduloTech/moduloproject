# Phase 6 - Sanctuary

**Estimate:** 2 days

## Objectives

- YAML configuration parser
- Inline marker detection
- Content merger with preservation
- Conflict resolution

## Configuration File

```yaml
# .moduloproject.yml
version: 1

# Override auto-detected values (optional)
context:
  ruby: "4"
  rails: "8.1"

# Files to completely ignore
ignore:
  - .gitlab-ci-custom.yml
  - docker/custom/

# Enable inline markers (default: true)
preserve_markers: true

# Explicit sanctuary zones
sanctuaries:
  - file: .gitlab-ci.yml
    sections:
      - "# CUSTOM START" .. "# CUSTOM END"
  - file: Dockerfile.prod
    lines: [45, 67]
  - file: .claude/settings.json
    sections:
      - "moduloproject:preserve:start" .. "moduloproject:preserve:end"
```

## Inline Markers

```yaml
# .gitlab-ci.yml

include:
  - template: integration.gitlab-ci.yml

# moduloproject:preserve:start
custom_deploy:
  stage: deploy
  script: ./custom-deploy.sh
  only:
    - master
# moduloproject:preserve:end
```

## Configuration Parser

```ruby
# lib/moduloproject/configuration.rb
module Moduloproject
  class Configuration
    CONFIG_FILE = ".moduloproject.yml".freeze

    def self.load(root = Dir.pwd)
      new(root).load
    end

    def initialize(root)
      @root = root
      @config_path = File.join(root, CONFIG_FILE)
    end

    def load
      return default_config unless File.exist?(@config_path)

      config = YAML.safe_load(File.read(@config_path), symbolize_names: true)
      validate!(config)
      default_config.deep_merge(config)
    end

    private

    def default_config
      {
        version: 1,
        context: {},
        ignore: [],
        preserve_markers: true,
        sanctuaries: [],
        mcp: {
          datadog: true,
          gitlab: true,
          github: false,
          jira: false,
          confluence: false,
          notion: false
        }
      }
    end

    def validate!(config)
      version = config[:version]
      raise ConfigurationError, "Unsupported config version: #{version}" if version && version > 1
    end
  end

  class ConfigurationError < StandardError; end
end
```

## Sanctuary Parser

```ruby
# lib/moduloproject/sanctuary/parser.rb
module Moduloproject
  module Sanctuary
    class Parser
      INLINE_MARKER_START = "moduloproject:preserve:start".freeze
      INLINE_MARKER_END = "moduloproject:preserve:end".freeze

      def initialize(config)
        @config = config
        @preserve_markers = config.fetch(:preserve_markers, true)
        @sanctuaries = config.fetch(:sanctuaries, [])
        @ignore = config.fetch(:ignore, [])
      end

      def ignored?(file)
        @ignore.any? { |pattern| File.fnmatch(pattern, file) }
      end

      def extract_zones(file, content)
        zones = []

        # Explicit sanctuaries from config
        zones.concat(extract_explicit_zones(file, content))

        # Inline markers
        zones.concat(extract_inline_zones(content)) if @preserve_markers

        zones
      end

      def preserve(file, old_content, new_content)
        return new_content if old_content.empty?
        return old_content if ignored?(file)

        zones = extract_zones(file, old_content)
        return new_content if zones.empty?

        Merger.new(old_content, new_content, zones).merge
      end

      private

      def extract_explicit_zones(file, content)
        sanctuary = @sanctuaries.find { |s| s[:file] == file }
        return [] unless sanctuary

        zones = []

        # Section-based zones
        sanctuary.fetch(:sections, []).each do |section|
          start_marker, end_marker = parse_section_range(section)
          zone = find_section(content, start_marker, end_marker)
          zones << zone if zone
        end

        # Line-based zones
        sanctuary.fetch(:lines, []).each do |line_num|
          lines = content.lines
          if line_num <= lines.length
            zones << { start: line_num - 1, end: line_num - 1, content: lines[line_num - 1] }
          end
        end

        zones
      end

      def extract_inline_zones(content)
        zones = []
        lines = content.lines

        in_zone = false
        zone_start = nil
        zone_content = []

        lines.each_with_index do |line, idx|
          if line.include?(INLINE_MARKER_START)
            in_zone = true
            zone_start = idx
            zone_content = [line]
          elsif line.include?(INLINE_MARKER_END) && in_zone
            zone_content << line
            zones << {
              start: zone_start,
              end: idx,
              content: zone_content.join,
              type: :inline
            }
            in_zone = false
            zone_content = []
          elsif in_zone
            zone_content << line
          end
        end

        zones
      end

      def parse_section_range(section)
        # Parse "start" .. "end" syntax
        match = section.match(/\A"(.+)"\s*\.\.\s*"(.+)"\z/)
        raise ConfigurationError, "Invalid section format: #{section}" unless match
        [match[1], match[2]]
      end

      def find_section(content, start_marker, end_marker)
        start_idx = content.index(start_marker)
        return nil unless start_idx

        end_idx = content.index(end_marker, start_idx)
        return nil unless end_idx

        end_idx += end_marker.length

        {
          start: content[0...start_idx].count("\n"),
          end: content[0...end_idx].count("\n"),
          content: content[start_idx..end_idx],
          markers: [start_marker, end_marker]
        }
      end
    end
  end
end
```

## Sanctuary Merger

```ruby
# lib/moduloproject/sanctuary/merger.rb
module Moduloproject
  module Sanctuary
    class Merger
      def initialize(old_content, new_content, zones)
        @old_content = old_content
        @new_content = new_content
        @zones = zones
      end

      def merge
        result = @new_content.dup

        # Sort zones by position (reverse to avoid offset issues)
        sorted_zones = @zones.sort_by { |z| -z[:start] }

        sorted_zones.each do |zone|
          result = insert_zone(result, zone)
        end

        result
      end

      private

      def insert_zone(content, zone)
        case zone[:type]
        when :inline
          insert_inline_zone(content, zone)
        else
          insert_section_zone(content, zone)
        end
      end

      def insert_inline_zone(content, zone)
        # Find matching markers in new content
        if zone[:content]
          start_marker = Sanctuary::Parser::INLINE_MARKER_START
          
          # Look for the marker position in new content
          marker_match = content.match(/.*#{Regexp.escape(start_marker)}.*\n(.*\n)*?.*moduloproject:preserve:end.*\n?/m)
          
          if marker_match
            # Replace the new zone with the old preserved content
            content.sub(marker_match[0], zone[:content])
          else
            # Marker not in new content, try to find a good insertion point
            # This is a conflict situation
            content
          end
        else
          content
        end
      end

      def insert_section_zone(content, zone)
        return content unless zone[:markers]

        start_marker, end_marker = zone[:markers]
        
        # Find the section in new content
        new_start = content.index(start_marker)
        return content unless new_start

        new_end = content.index(end_marker, new_start)
        return content unless new_end

        new_end += end_marker.length

        # Replace with preserved content
        content[0...new_start] + zone[:content] + content[new_end..]
      end
    end
  end
end
```

## Conflict Resolution

```ruby
# lib/moduloproject/sanctuary/conflict_resolver.rb
module Moduloproject
  module Sanctuary
    class ConflictResolver
      def initialize(prompt)
        @prompt = prompt
      end

      def resolve(file, old_zone, new_content)
        display_conflict(file, old_zone, new_content)

        choice = @prompt.select("How do you want to resolve this?") do |menu|
          menu.choice "Keep my version (skip template change)", :keep
          menu.choice "Accept template change (lose sanctuary content)", :accept
          menu.choice "Merge both (if possible)", :merge
          menu.choice "Open in editor to resolve manually", :edit
          menu.choice "Skip this file for now", :skip
        end

        case choice
        when :keep
          { action: :keep, content: old_zone[:content] }
        when :accept
          { action: :accept, content: new_content }
        when :merge
          attempt_smart_merge(old_zone, new_content)
        when :edit
          { action: :edit }
        when :skip
          { action: :skip }
        end
      end

      private

      def display_conflict(file, old_zone, new_content)
        puts TTY::Box.frame(
          "CONFLICT in #{file}",
          "Sanctuary zone overlaps with required template change",
          "",
          "Template wants to change content in a preserved zone.",
          padding: 1,
          border: :round
        )
      end

      def attempt_smart_merge(old_zone, new_content)
        # For JSON files, try to merge objects
        if json_content?(old_zone[:content]) && json_content?(new_content)
          merged = smart_merge_json(old_zone[:content], new_content)
          return { action: :merge, content: merged } if merged
        end

        # Can't auto-merge
        { action: :manual_required }
      end

      def json_content?(content)
        JSON.parse(content)
        true
      rescue JSON::ParserError
        false
      end

      def smart_merge_json(old_json, new_json)
        old_data = JSON.parse(old_json)
        new_data = JSON.parse(new_json)
        
        merged = new_data.deep_merge(old_data)
        JSON.pretty_generate(merged)
      rescue StandardError
        nil
      end
    end
  end
end
```

## Deliverables

- [ ] Configuration class with YAML parsing
- [ ] Sanctuary::Parser with inline marker detection
- [ ] Sanctuary::Merger with zone preservation
- [ ] Sanctuary::ConflictResolver with interactive resolution
- [ ] Smart JSON merge for settings files
- [ ] Unit tests for all zone extraction scenarios
- [ ] Integration tests for merge scenarios
