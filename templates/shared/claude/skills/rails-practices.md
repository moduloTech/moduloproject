# Skill: Rails Best Practices

Apply Rails conventions and best practices to the codebase.

## Architecture
- Fat models, skinny controllers
- Use service objects for complex business logic
- Use concerns for shared model behavior
- Use form objects for complex form handling
- Use query objects for complex database queries

## Models
- Validate at the model level, not just the database level
- Use scopes for common queries
- Keep callbacks simple; prefer service objects for complex side effects
- Use `has_many through:` for many-to-many relationships

## Controllers
- Use strong parameters for mass assignment protection
- Use `before_action` for shared setup
- Keep actions to the standard 7 RESTful actions
- Create new controllers for non-standard actions

## Views
- Use partials for reusable components
- Use helpers for view-specific logic
- Keep logic out of views; use presenters/decorators if needed

## Security
- Always use parameterized queries (never string interpolation in SQL)
- Use `content_security_policy` headers
- Sanitize user input in views with `sanitize` helper
- Use `protect_from_forgery` (enabled by default)
