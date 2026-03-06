# Prevent Destructive Operations

## Database
- NEVER run `db:drop`, `db:reset`, or `db:purge` without explicit confirmation
- NEVER write raw SQL `DROP TABLE`, `TRUNCATE`, or mass `DELETE` statements
- Always use reversible migrations with `change` method when possible
- Test migrations on a copy before applying to shared environments

## Files
- NEVER delete files outside the project directory
- NEVER overwrite files without reading them first
- NEVER modify `.env` files that may contain production secrets
- Always check `git status` before discarding changes

## System
- NEVER kill processes without understanding what they do
- NEVER modify system-level configuration files
- NEVER run `rm -rf` on directories without explicit path verification
