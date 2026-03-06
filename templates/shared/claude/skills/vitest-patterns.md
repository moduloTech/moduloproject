# Skill: Vitest Patterns

Write Vitest tests for Vue.js components and JavaScript code.

## Component Test Template

```javascript
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import MyComponent from '@/components/MyComponent.vue'

describe('MyComponent', () => {
  it('renders the title', () => {
    const wrapper = mount(MyComponent, {
      props: { title: 'Hello' }
    })
    expect(wrapper.text()).toContain('Hello')
  })

  it('emits update event on click', async () => {
    const wrapper = mount(MyComponent, {
      props: { title: 'Test' }
    })
    await wrapper.find('button').trigger('click')
    expect(wrapper.emitted('update')).toBeTruthy()
  })
})
```

## Conventions
- Mirror the source directory structure in tests
- Name test files as `ComponentName.spec.js`
- Use `describe` for component/module, `it` for specific behavior
- Test user-visible behavior, not internal state

## Mocking
- Use `vi.mock()` for module mocking
- Use `vi.fn()` for function stubs
- Mock API calls with `vi.spyOn` or MSW
- Reset mocks between tests with `beforeEach`

## Async Testing
- Use `await nextTick()` after state changes
- Use `await wrapper.vm.$nextTick()` for DOM updates
- Use `flushPromises()` for async operations

## Coverage
- Run `vitest run --coverage` for coverage report
- Aim for meaningful coverage, not 100% line coverage
- Focus on testing component contracts (props in, events out)
