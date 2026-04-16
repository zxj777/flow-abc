# Rule Example: React / Next.js Conventions

> Style reference for React/Next.js projects. Adapt to the project's actual patterns.

---

## Components

### Functional Components Only
**Level**: MUST
- Always use function components, not class components
- Named exports preferred, default export for page entry points

```tsx
// ✅
export function UserProfile({ userId }: UserProfileProps) {
  return <div>...</div>;
}

// ❌
class UserProfile extends React.Component { }
```

### Props Destructuring
**Level**: SHOULD
- Destructure props in the parameter position
- Provide defaults for optional props

```tsx
export function Button({
  type = 'default',
  size = 'md',
  loading = false,
  children,
  onClick,
}: ButtonProps) { ... }
```

---

## Hooks

### Custom Hooks
**Level**: MUST
- `use` prefix naming
- Single responsibility
- Return objects (not arrays, unless simple [value, setter] pattern)

```tsx
export function useOrderList(params: OrderListParams) {
  const [orders, setOrders] = useState<OrderVO[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getOrderList(params);
      setOrders(data.map(adaptOrder));
    } catch (e) {
      message.error('Failed to load orders');
    } finally {
      setLoading(false);
    }
  }, [params]);

  useEffect(() => { refresh(); }, [refresh]);

  return { orders, loading, refresh };
}
```

### Dependencies & Cleanup
**Level**: MUST
- Complete dependency arrays (follow exhaustive-deps rule)
- Effects with side effects must return cleanup functions
- Handle component unmount in async operations

---

## State Management

### State Layering
**Level**: SHOULD

| Data Type | Solution | Example |
|---|---|---|
| Local UI state | `useState` | Modal open, input value |
| Derived data | `useMemo` | Filtered list |
| Cross-component | Zustand / Context | User info, theme |
| Server cache | React Query / SWR | API data lists |

### State Placement
- State in nearest common ancestor
- Avoid unnecessary global state
- Context only for truly global data (theme, locale, auth)

---

## Performance

**Level**: SHOULD
- `memo` for list items and heavy child components
- `useCallback` for callbacks passed to children
- Unique `key` for list rendering (id, not index)
- Virtual scrolling for large lists (>100 items)

---

## JSX

### Conditional Rendering
**Level**: SHOULD

```tsx
// ✅ Short-circuit
{isLoading && <Spinner />}

// ✅ Ternary
{isError ? <ErrorMessage /> : <DataTable />}

// ✅ Early return for complex conditions
if (isLoading) return <Spinner />;
if (isError) return <ErrorMessage />;
return <DataTable />;

// ❌ Nested ternary
{isLoading ? <Spinner /> : isError ? <Error /> : <Data />}
```

### Event Handler Naming
- Props: `onXxx` (`onClick`, `onChange`)
- Internal: `handleXxx` (`handleSubmit`, `handleClick`)

---

## Next.js Specific (if applicable)

### Data Fetching
**Level**: MUST
- Server Components for data fetching by default
- Client Components only for interactive parts
- Mark with `'use client'` directive

### Routing
**Level**: SHOULD
- App Router (Next.js 13+)
- Pages in `app/` directory
- Shared layouts via `layout.tsx`
