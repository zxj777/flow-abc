# Rule Example: Architecture Constraints

> This is a **style reference** for AI rule generation. When initializing a project,
> analyze the actual project code and generate rules in this format, adapted to the
> project's real conventions.

## Example Rule Format

Rules use severity levels:
- **MUST**: Mandatory rule, violation is a bug or convention break
- **SHOULD**: Recommended practice, deviation needs justification
- **MAY**: Optional suggestion

Each rule has: severity level → description → code examples (✅ correct / ❌ wrong).

---

## Directory Structure

### Standard Layout
**Level**: MUST
- Follow the project's established directory structure
- New files must be placed in the correct directory by type

```
src/
├── api/              # API call functions (one file per domain)
├── adapters/         # Backend DTO → Frontend VO transformers
├── components/       # Shared components (used by 2+ pages)
├── composables/      # Shared composables / hooks
├── constants/        # Shared constants
├── pages/            # Page components
│   └── [module]/
│       ├── index.tsx          # Page entry
│       └── components/        # Page-private components
├── stores/           # State management (Pinia / Zustand)
├── types/            # Shared type definitions
└── utils/            # Pure utility functions
```

### Module Boundaries
**Level**: MUST
- Page-private components stay in `pages/[module]/components/`
- Promote to `src/components/` only when used by 2+ pages
- Never import from another page's private `components/` directory

```typescript
// ✅ Shared component
import { DataTable } from '@/components/DataTable';

// ✅ Same-page private component
import { OrderFilter } from './components/OrderFilter';

// ❌ Cross-page private import
import { UserAvatar } from '@/pages/user/components/UserAvatar';
```

---

## API Layer

### Request Wrapper
**Level**: MUST
- All HTTP requests go through the project's request wrapper
- API functions organized by domain: `src/api/user.ts`, `src/api/order.ts`
- Each function has typed parameters and return types

```typescript
// ✅ src/api/user.ts
export function getUser(id: string): Promise<ApiResponse<UserDTO>> {
  return request.get(`/users/${id}`);
}

export function updateUser(id: string, data: UpdateUserParams): Promise<ApiResponse<void>> {
  return request.put(`/users/${id}`, data);
}

// ❌ Direct fetch in component
const res = await fetch(`/api/users/${id}`);
```

### Data Flow
**Level**: MUST
- Strict one-way data flow: API → Adapter → Component
- Components never consume raw API response shapes
- Backend field naming (snake_case) never leaks into component layer

```
API (DTO) → Adapter (transform) → Component (VO)
                ↑
    src/adapters/user.adapter.ts
```

---

## State Management

### State Layering
**Level**: MUST
- Follow the project's state management hierarchy
- Don't put local UI state into global store
- Don't use global state for data that should be server cache

| Scope | Solution | Example |
|---|---|---|
| Component-local | `useState` / `ref` | Form inputs, modal open |
| Derived | `useMemo` / `computed` | Filtered/sorted lists |
| Server data | React Query / SWR / `useFetch` | API responses |
| Global client state | Zustand / Pinia | Auth, theme, locale |

### Store Organization
**Level**: SHOULD
- One store per domain (user store, order store)
- Store files in `src/stores/`
- No business logic in stores — stores hold state, services hold logic

---

## Component Architecture

### Layering
**Level**: SHOULD
- Page components: layout + composition, minimal logic
- Container components: data fetching + state wiring
- Presentational components: pure rendering from props

### Prop Design
**Level**: SHOULD
- Max 5-7 props per component; more suggests need for refactoring
- Use object props for related groups of values
- Prefer composition (children / slots) over configuration props

```tsx
// ✅ Composition
<Card>
  <Card.Header>Title</Card.Header>
  <Card.Body>{content}</Card.Body>
</Card>

// ❌ Configuration prop overload
<Card
  title="Title"
  showHeader={true}
  headerStyle="bold"
  bodyContent={content}
  showFooter={false}
/>
```

---

## Routing

### Route Organization
**Level**: SHOULD
- Routes reflect URL structure
- Route-level code splitting (lazy loading)
- Route guards / middleware for auth and permissions

```typescript
// ✅ Lazy loaded routes
const UserPage = lazy(() => import('@/pages/user'));

// ❌ Eager import of all pages
import UserPage from '@/pages/user';
import OrderPage from '@/pages/order';
import SettingsPage from '@/pages/settings';
```

### URL Design
**Level**: SHOULD
- RESTful URL patterns: `/users`, `/users/:id`, `/users/:id/orders`
- Use query params for filters, sorting, pagination
- No business data in URL that should be in state

---

## Error Handling

### Error Boundaries
**Level**: MUST
- Page-level error boundaries to prevent full-app crashes
- Provide meaningful fallback UI, not blank screens
- Log errors to monitoring service

### API Error Handling
**Level**: MUST
- Centralized error handling in request wrapper (auth errors, network errors)
- Page-level handling for business errors (validation, not found)
- User-facing error messages, not raw server errors

```typescript
// ✅ Centralized in request wrapper
request.interceptors.response.use(
  (res) => res,
  (error) => {
    if (error.response?.status === 401) {
      redirectToLogin();
    }
    return Promise.reject(error);
  }
);

// ✅ Business error in page
try {
  await submitOrder(data);
} catch (e) {
  if (e.code === 'INSUFFICIENT_STOCK') {
    message.error('Stock not enough');
  }
}
```

---

## Dependencies

### Package Management
**Level**: MUST
- No new dependencies without justification
- Check if existing dependencies already solve the problem
- Avoid packages with overlapping functionality

### Internal Dependencies
**Level**: MUST
- No circular dependencies between modules
- Dependency direction: Pages → Components → Utils (never reverse)
- Shared types in `src/types/`, not re-exported across modules
