# Rule Example: Testing Conventions

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

## Test File Organization

### File Location
**Level**: MUST
- Co-locate tests with source: `UserProfile.test.tsx` next to `UserProfile.tsx`
- Or mirror in `__tests__/` directory (follow existing project pattern)
- Test utils / helpers in `tests/helpers/` or `__tests__/utils/`

### File Naming
**Level**: MUST
- Unit / component tests: `[SourceName].test.ts(x)`
- Integration tests: `[Feature].integration.test.ts`
- E2E tests: `[Flow].e2e.test.ts` or in `e2e/` directory

---

## Test Structure

### Describe / It Pattern
**Level**: MUST
- Top-level `describe` = module or component name
- Nested `describe` = method, state, or scenario group
- `it` description = expected behavior in plain language

```typescript
// ✅
describe('UserProfile', () => {
  describe('when user is logged in', () => {
    it('displays the avatar and username', () => { ... });
    it('shows the edit button', () => { ... });
  });

  describe('when user is not logged in', () => {
    it('shows the login prompt', () => { ... });
  });
});

// ❌
describe('test', () => {
  it('test1', () => { ... });
  it('works', () => { ... });
});
```

### AAA Pattern
**Level**: SHOULD
- Arrange → Act → Assert structure
- Separate sections with blank lines for readability

```typescript
// ✅
it('filters active users from the list', () => {
  const users = [
    { id: '1', name: 'Alice', status: 'active' },
    { id: '2', name: 'Bob', status: 'inactive' },
  ];

  const result = filterActiveUsers(users);

  expect(result).toEqual([{ id: '1', name: 'Alice', status: 'active' }]);
});
```

---

## Mocking

### Mock Scope
**Level**: MUST
- Mock at module boundaries (API calls, external services)
- Never mock the unit under test
- Reset mocks in `beforeEach` or `afterEach`

```typescript
// ✅ Mock the API layer
vi.mock('@/api/user', () => ({
  getUser: vi.fn(),
}));

// ❌ Mock internal implementation details
vi.mock('./utils/formatName');
```

### Mock Data
**Level**: SHOULD
- Use factory functions for test data, not shared mutable objects
- Keep mock data minimal — only fields the test cares about

```typescript
// ✅
function createMockUser(overrides: Partial<UserVO> = {}): UserVO {
  return {
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
    ...overrides,
  };
}

// ❌ Shared mutable object across tests
const mockUser = { id: '1', name: 'Test User' };
```

---

## Component Testing

### Render & Query
**Level**: MUST
- Query by role, label, or text (accessible queries first)
- Avoid querying by test ID unless no semantic alternative
- Avoid querying by class name or tag

```typescript
// ✅
screen.getByRole('button', { name: 'Submit' });
screen.getByLabelText('Email address');

// ❌
document.querySelector('.btn-submit');
screen.getByTestId('submit-button');
```

### User Interaction
**Level**: SHOULD
- Use `userEvent` over `fireEvent` for realistic behavior
- Test from the user's perspective, not implementation

```typescript
// ✅
await userEvent.click(screen.getByRole('button', { name: 'Save' }));
expect(screen.getByText('Saved successfully')).toBeInTheDocument();

// ❌
fireEvent.click(wrapper.find('#save-btn'));
expect(mockFn).toHaveBeenCalledTimes(1);
```

---

## Async Testing

**Level**: MUST
- Use `waitFor` or `findBy*` for async assertions
- Never use arbitrary `setTimeout` / `sleep` in tests
- Always `await` async operations

```typescript
// ✅
await waitFor(() => {
  expect(screen.getByText('Loading complete')).toBeInTheDocument();
});

// ❌
await new Promise(r => setTimeout(r, 1000));
expect(screen.getByText('Loading complete')).toBeInTheDocument();
```

---

## Coverage & Scope

### What to Test
**Level**: SHOULD
- Business logic and data transformations
- Component rendering with different prop combinations
- User interaction flows
- Edge cases and error states
- Adapter / transformer functions

### What NOT to Test
**Level**: SHOULD
- Static markup with no logic
- Third-party library internals
- Exact CSS / style values
- Implementation details (internal state, private methods)

### Coverage
**Level**: SHOULD
- Aim for meaningful coverage, not 100%
- Critical paths (auth, payments, data mutations) must have tests
- New features should include tests; bug fixes should include regression tests
