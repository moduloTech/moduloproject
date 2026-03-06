# Skill: RSpec Patterns

Write well-structured RSpec tests following project conventions.

## Structure

```ruby
RSpec.describe ClassName do
  describe '#method_name' do
    context 'when condition is met' do
      it 'does the expected thing' do
        # arrange, act, assert
      end
    end

    context 'when condition is not met' do
      it 'handles the edge case' do
      end
    end
  end
end
```

## Conventions
- Use `let` for setup, `subject` for the thing being tested
- Use `described_class` instead of hardcoding class names
- Use `context` for different scenarios, `describe` for methods
- Prefix `context` blocks with "when", "with", or "without"
- One assertion per `it` block (when practical)

## Factories
- Use FactoryBot for test data
- Define minimal factories with only required attributes
- Use traits for variations
- Use sequences for unique values

## Mocking
- Prefer real objects over mocks when practical
- Use `instance_double` for type-checked doubles
- Mock external services at the HTTP level (WebMock/VCR)
- Never mock the object under test

## Coverage
- Test happy path and error cases
- Test boundary conditions
- Test model validations and associations
- Test controller responses and redirects
- Test service object edge cases
