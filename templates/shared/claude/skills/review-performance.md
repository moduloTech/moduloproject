# Skill: Performance Review

Analyze code for performance issues and optimization opportunities.

## Steps

1. Identify the scope of analysis (specific files, endpoint, or full app)
2. Check for common Rails performance issues:
   - **N+1 queries**: Missing `includes`, `preload`, or `eager_load`
   - **Missing indexes**: Columns used in `WHERE`, `ORDER BY`, or `JOIN`
   - **Expensive callbacks**: Heavy operations in model callbacks
   - **Memory bloat**: Loading large datasets into memory
   - **Unnecessary queries**: Repeated queries that could be cached

3. Review database queries:
   - Check `db/schema.rb` for missing indexes
   - Look for `select *` patterns (use `select` or `pluck` instead)
   - Identify queries that could use counter caches

4. Review application code:
   - Background job candidates (emails, external API calls, reports)
   - Caching opportunities (fragment, action, or Russian doll caching)
   - Pagination for large collections

## Output
- List issues by severity (critical, warning, suggestion)
- Include estimated impact and recommended fix
- Provide code examples for suggested optimizations
