# Skill: Migration

Create a Rails database migration.

## Steps

1. Determine the migration name using Rails conventions
2. Generate the migration file with `bundle exec rails generate migration MigrationName`
3. Edit the migration to implement the schema change
4. Ensure the migration is reversible (use `change` method)
5. Run `bundle exec rails db:migrate` to apply
6. Verify with `bundle exec rails db:migrate:status`

## Rules
- Always use reversible migrations when possible
- Add database indexes for foreign keys and frequently queried columns
- Use `null: false` constraints where appropriate
- Add comments to non-obvious columns using `comment:` option
- For large tables, consider using `disable_ddl_transaction!` and `algorithm: :concurrently` for indexes
- Never modify a migration that has already been run in shared environments
- Test both `db:migrate` and `db:rollback`
