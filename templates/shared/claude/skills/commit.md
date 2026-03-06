# Skill: Commit

Create a well-structured git commit for the current changes.

## Steps

1. Run `git status` and `git diff --cached` to understand staged changes
2. If nothing is staged, run `git diff` to see unstaged changes and suggest what to stage
3. Write a commit message following Conventional Commits format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `refactor:` for code restructuring
   - `test:` for adding/updating tests
   - `docs:` for documentation changes
   - `chore:` for maintenance tasks
   - `style:` for formatting changes
4. Keep the subject line under 72 characters
5. Add a body if the change needs explanation (what and why, not how)
6. Stage and commit the changes

## Rules
- Never commit secrets, credentials, or `.env` files
- Never use `--no-verify` to skip hooks
- Never amend published commits without explicit approval
- One logical change per commit
