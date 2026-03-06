# Phase 6 - Sanctuary

**Status:** TODO

## Objectives

- [ ] YAML configuration parser (`.moduloproject.yml` sanctuary sections)
- [ ] Inline marker detection (`moduloproject:preserve:start/end`)
- [ ] Content merger with zone preservation
- [ ] Conflict resolution (interactive)

## Configuration File

```yaml
# .moduloproject.yml (already exists as keepfile, extend it)
version: 1

# Files to completely ignore during sync
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

## Implementation Plan

### Sanctuary::Parser

- Extracts zones from inline markers
- Extracts zones from explicit YAML config
- Determines if a file should be ignored entirely

### Sanctuary::Merger

- Takes old content, new content, and preserved zones
- Replaces zones in new content with preserved content from old
- Handles offset adjustments when zones move

### Sanctuary::ConflictResolver

- Interactive resolution when sanctuary zones conflict with template changes
- Options: keep mine, accept template, merge both, open in editor, skip

### Integration with Sync (Phase 5)

The `DiffGenerator` calls `Sanctuary::Parser.preserve(file, old_content, new_content)`
before computing the diff.

## Notes

This phase can be implemented after Phase 5 (sync without sanctuary),
then retrofitted into the sync pipeline as an enhancement.
