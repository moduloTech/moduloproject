# Skill: Code Review

Perform a thorough code review of the specified files or changes.

## Steps

1. Run `git diff` (or `git diff --cached`) to see the changes
2. Analyze each change for:
   - **Correctness**: Does it do what it's supposed to?
   - **Security**: Any vulnerabilities (SQL injection, XSS, mass assignment)?
   - **Performance**: N+1 queries, missing indexes, expensive operations?
   - **Readability**: Clear naming, appropriate comments, consistent style?
   - **Testing**: Are changes covered by tests? Are edge cases handled?
   - **Rails conventions**: Following established patterns?

## Output Format

For each issue found, report:
- **File:line** — description of the issue
- **Severity**: critical / warning / suggestion
- **Recommendation**: what to change and why

## Rules
- Focus on substantive issues, not style nitpicks (RuboCop handles style)
- Check for missing test coverage on new code paths
- Verify database migrations are reversible
- Look for hardcoded values that should be configuration
- Check error handling and edge cases
