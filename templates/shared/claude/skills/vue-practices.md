# Skill: Vue.js Practices

Write Vue.js components following project conventions.

## Component Template

```vue
<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  title: { type: String, required: true }
})

const emit = defineEmits(['update'])

const count = ref(0)
const doubled = computed(() => count.value * 2)

function increment() {
  count.value++
  emit('update', count.value)
}
</script>

<template>
  <div class="component-name">
    <h2>{{ title }}</h2>
    <button @click="increment">{{ count }} ({{ doubled }})</button>
  </div>
</template>

<style scoped>
.component-name {
  /* component styles */
}
</style>
```

## Conventions
- Use `<script setup>` for all components
- Define props with types and required flags
- Use `defineEmits` for component events
- Prefer composables (`use*.js`) for reusable logic
- Keep components focused and small

## State Management
- Use Pinia stores for shared state
- Keep component state local when possible
- Use provide/inject sparingly

## Routing
- Use Vue Router for navigation
- Define routes with lazy loading: `() => import('./views/Page.vue')`
- Use route guards for authentication

## Testing with Vitest
- Mount components with `@vue/test-utils`
- Test user interactions, not implementation
- Mock API calls and stores
- Use `@testing-library/vue` for accessibility-focused tests
