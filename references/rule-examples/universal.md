# Rule Example: Universal Coding Conventions

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

## Naming Conventions

### File Naming
**Level**: MUST
- Components: PascalCase (`UserProfile.tsx`)
- Hooks / Composables: camelCase + `use` prefix (`useUserList.ts`)
- Utils: camelCase (`formatDate.ts`)
- Types: camelCase (`types.ts`)
- Tests: source name + `.test` (`UserProfile.test.tsx`)

### Variable Naming
**Level**: MUST
- Components: PascalCase (`UserProfile`)
- Functions/variables: camelCase (`getUserList`, `isLoading`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)
- Types/interfaces: PascalCase (`UserVO`, `OrderStatus`)
- Booleans: `is`/`has`/`should`/`can` prefix (`isVisible`, `hasPermission`)

---

## TypeScript

### Type Definitions
**Level**: MUST
- Component Props: use `interface`, export it
- No `any` — use `unknown` + type narrowing
- API responses must have type definitions
- Prefer `interface` for objects, `type` for unions/intersections

```typescript
// ✅
export interface UserProfileProps {
  userId: string;
  showAvatar?: boolean;
}

// ❌
export function UserProfile(props: any) { }
```

### Type Imports
**Level**: SHOULD
- Use `import type` for type-only imports

```typescript
import type { UserVO } from '@/types/user';
```

---

## Imports

### Import Order
**Level**: SHOULD
1. Framework core (react, vue)
2. Third-party libraries
3. Project alias imports (`@/`)
4. Relative imports
5. Style files

(Groups separated by blank lines)

### Path References
**Level**: MUST
- Cross-module: use path alias (`@/components/Button`)
- Within module: use relative paths (`./components/UserAvatar`)
- Never: cross-module relative paths (`../../../components/Button`)

---

## API Calls

### Request Pattern
**Level**: MUST
- Use the project's existing request wrapper
- Never use raw `fetch` or `axios` directly
- API functions in `src/api/[module].ts` or `src/services/[module].ts`

### Error Handling
**Level**: MUST
- All API calls must have error handling
- No silent Promise rejections

### Data Transformation (Adapter Pattern)
**Level**: MUST
- Backend data → adapter → frontend ViewModel (VO)
- Components never use raw backend field names
- Adapter files: `src/adapters/[module].adapter.ts`

```typescript
export function adaptUser(raw: ApiUserDTO): UserVO {
  return {
    id: raw.id,
    displayName: raw.user_name,
    isActive: raw.status === 1,
  };
}
```

---

## Components

### Reuse
**Level**: MUST
- Use existing components from `src/components/`
- Never recreate functionality that existing components provide
- New component creation requires justification

### Structure
**Level**: SHOULD
- Single component file < 300 lines
- Reusable logic → custom hooks
- Page-private components → `pages/[module]/components/`
- Shared components (2+ pages) → `src/components/`

---

## Incremental Development

**Level**: MUST
- Read and understand existing code before modifying
- New code must match existing style
- Don't create duplicates of existing functions/components
- Don't import uninstalled packages without confirmation
