# Git Safety Rules

## Branch Protection
- NEVER force-push to protected branches (main, master, develop, staging, production)
- NEVER delete remote branches without explicit user approval
- Always create feature branches for changes

## Commit Discipline
- Write clear, descriptive commit messages following Conventional Commits
- Keep commits atomic: one logical change per commit
- Never commit secrets, credentials, or API keys
- Never commit large binary files

## Merge Strategy
- Prefer rebase for feature branches to keep history clean
- Use merge commits for integration branches
- Always resolve conflicts carefully, preserving both sides' intent

## Pre-push Checklist
- All tests pass
- Linter has no errors
- No debug code (binding.pry, console.log, debugger)
- No TODO comments that should be tickets
