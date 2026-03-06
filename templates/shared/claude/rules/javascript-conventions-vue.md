# JavaScript Conventions — Vue.js

## Component Structure
- Use `<script setup>` with Composition API for all new components
- Order template sections: `<script setup>`, `<template>`, `<style scoped>`
- One component per file, named in PascalCase

## Naming
- Components: `PascalCase.vue` (e.g., `UserProfile.vue`)
- Composables: `useCamelCase.js` (e.g., `useAuth.js`)
- Stores: `camelCaseStore.js` (e.g., `userStore.js`)
- Constants: `UPPER_SNAKE_CASE`

## State Management
- Use Pinia for global state
- Keep component state local when possible
- Use composables for shared logic without global state

## Reactivity
- Prefer `ref()` for primitives, `reactive()` for objects
- Use `computed()` for derived values
- Avoid mutating props directly

## Testing
- Use Vitest + Vue Test Utils for component tests
- Test behavior, not implementation details
- Use `@testing-library/vue` for user-centric tests

## ESLint
- Follow `eslint-plugin-vue/vue3-recommended` rules
- Run `npx eslint --fix` before committing
