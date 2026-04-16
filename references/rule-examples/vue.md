# Rule Example: Vue / Nuxt Conventions

> Style reference for Vue 3 / Nuxt projects. Adapt to the project's actual patterns.

---

## Components

### Composition API with `<script setup>`
**Level**: MUST
- Always use `<script setup lang="ts">`
- No Options API, no `defineComponent`

```vue
<script setup lang="ts">
import { ref, computed } from 'vue';

interface Props {
  userId: string;
  showAvatar?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  showAvatar: true,
});

const emit = defineEmits<{
  edit: [id: string];
  delete: [id: string];
}>();
</script>
```

### Props & Events
**Level**: MUST
- TypeScript generics for Props (`defineProps<T>()`)
- `withDefaults` for default values
- `defineEmits<T>()` for typed events

### Component Naming
**Level**: MUST
- PascalCase in templates (`<UserProfile />`)
- PascalCase file names (`UserProfile.vue`)

---

## Composables

### Structure
**Level**: MUST
- `use` prefix naming
- Files in `composables/` directory
- Return reactive data with `ref`

```typescript
export function useOrderList(params: Ref<OrderListParams>) {
  const orders = ref<OrderVO[]>([]);
  const loading = ref(false);

  async function refresh() {
    loading.value = true;
    try {
      const data = await getOrderList(params.value);
      orders.value = data.map(adaptOrder);
    } catch (e) {
      message.error('Failed to load orders');
    } finally {
      loading.value = false;
    }
  }

  watch(params, refresh, { immediate: true, deep: true });

  return { orders, loading, refresh };
}
```

### Reactivity
**Level**: SHOULD
- `ref` for primitives and objects/arrays
- Avoid `reactive` (destructuring loses reactivity)
- Reactive parameters: accept `Ref<T>` or `() => T`

---

## Templates

### Directives
**Level**: SHOULD
- `v-if`/`v-else` for conditional rendering
- `v-show` for frequent toggles
- `v-for` must have `:key` with unique id

### Template Expressions
**Level**: SHOULD
- Complex logic → `computed`, not inline expressions
- Keep template expressions to one line max

```vue
<!-- ❌ -->
<div>{{ items.filter(i => i.active).map(i => i.name).join(', ') }}</div>

<!-- ✅ -->
<div>{{ activeNames }}</div>
<script setup>
const activeNames = computed(() =>
  items.value.filter(i => i.active).map(i => i.name).join(', ')
);
</script>
```

---

## State Management

### State Layering
**Level**: SHOULD

| Data Type | Solution | Example |
|---|---|---|
| Local state | `ref` / `reactive` | Modal, input |
| Derived | `computed` | Filtered list |
| Cross-component | Pinia | User info, auth |
| Parent-child | Props + Emits | Form data |
| Cross-level | `provide` / `inject` | Theme, config |

### Pinia (if used)
**Level**: SHOULD
- Setup Store style (matches Composition API)
- One store per domain module
- Store files in `src/stores/`

```typescript
export const useUserStore = defineStore('user', () => {
  const currentUser = ref<UserVO | null>(null);
  const isLoggedIn = computed(() => !!currentUser.value);

  async function fetchCurrentUser() {
    const data = await getCurrentUser();
    currentUser.value = adaptUser(data);
  }

  return { currentUser, isLoggedIn, fetchCurrentUser };
});
```

---

## Performance

**Level**: SHOULD
- Use `computed` for derived data (auto-cached)
- Route-level lazy loading: `defineAsyncComponent` or router lazy
- `v-for` `:key` with unique id (not index)
- Virtual scrolling for large lists (>100 items)

---

## Nuxt Specific (if applicable)

### Data Fetching
**Level**: MUST
- Use `useFetch` / `useAsyncData`
- Don't fetch in `onMounted`

### Auto-imports
**Level**: SHOULD
- Leverage Nuxt auto-imports (composables, components)
- Don't manually import Vue APIs (`ref`, `computed` are auto-imported)
