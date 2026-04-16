# Rule Example: Code Review Rules

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

## Review Principles

### Signal-to-Noise
**Level**: MUST
- Only flag issues that genuinely matter
- Never comment on formatting or style that linters handle
- Never comment on personal preference without project convention backing
- Each comment must be actionable with a clear fix

### Severity Classification
**Level**: MUST
- Classify every finding by severity:

| Severity | Meaning | Example |
|---|---|---|
| 🔴 Blocker | Bug, data loss, security vulnerability | Unescaped user input in HTML |
| 🟡 Warning | Logic risk, performance issue, convention violation | Missing error handling on API call |
| 🔵 Suggestion | Improvement idea, readability | Extract repeated logic into helper |

- Blockers must be fixed before merge
- Warnings should be addressed or justified
- Suggestions are optional improvements

---

## Review Checklist

### Correctness
**Level**: MUST
- Logic matches the stated requirements
- Edge cases handled (empty data, null, boundary values)
- No off-by-one errors, race conditions, or unhandled promises
- State updates are correct (no stale closures, no direct mutation)

### Security
**Level**: MUST
- No user input rendered as raw HTML (XSS)
- No secrets or credentials in code
- API calls use proper authentication
- Sensitive data not logged or exposed in error messages

### Data Flow
**Level**: MUST
- API responses pass through adapters before reaching components
- No raw backend field names (snake_case) in component layer
- Type safety maintained across boundaries (no `any` escape hatches)

### Error Handling
**Level**: MUST
- All API calls have error handling
- No silent `catch` blocks that swallow errors
- User sees meaningful feedback on failure, not blank screen

```typescript
// 🔴 Blocker: Silent error swallowing
try {
  await submitOrder(data);
} catch (e) {
  // nothing
}

// ✅
try {
  await submitOrder(data);
} catch (e) {
  message.error('Failed to submit order');
  logger.error('Order submission failed', e);
}
```

---

## Change Scope Review

### Minimal & Focused
**Level**: SHOULD
- Changes match the stated purpose (PR title / commit message)
- No unrelated refactors bundled with feature changes
- Dead code is removed, not commented out

### Impact Analysis
**Level**: SHOULD
- Consider downstream impact of changed functions / components
- Shared component changes reviewed for all usage sites
- Type changes checked for compatibility across consumers

---

## Performance Review

### Rendering
**Level**: SHOULD
- No unnecessary re-renders caused by new object / array / function refs in render
- Large lists use virtualization
- Heavy computations wrapped in `useMemo` / `computed`

```typescript
// 🟡 Warning: New object reference every render → child re-renders
function Parent() {
  return <Child style={{ color: 'red' }} />;
}

// ✅
const childStyle = { color: 'red' };
function Parent() {
  return <Child style={childStyle} />;
}
```

### Data Fetching
**Level**: SHOULD
- No duplicate API calls for the same data
- No fetch in loops without batching
- Loading and error states handled

---

## Testing Review

### Coverage of Changes
**Level**: SHOULD
- New features include corresponding tests
- Bug fixes include regression tests
- Removed tests are justified (not just deleted to pass CI)

### Test Quality
**Level**: SHOULD
- Tests verify behavior, not implementation
- Test descriptions explain the expected outcome
- No flaky patterns (arbitrary timeouts, order-dependent tests)

---

## Review Comment Format

### How to Comment
**Level**: MUST
- Lead with severity emoji (🔴 / 🟡 / 🔵)
- State the problem clearly in one line
- Provide a fix or suggestion
- Reference project rule if applicable

```markdown
🔴 **Unhandled API error** — `fetchUser()` has no catch block.
If the request fails, the component will show a blank screen.

Suggestion: Add try/catch with user-facing error message.
See: `.ai/rules/architecture.md` §Error Handling

🔵 **Extract repeated logic** — The date formatting on lines 42 and 78
is duplicated. Consider extracting to `utils/formatDate.ts`.
```

### What NOT to Comment
**Level**: MUST
- Formatting issues (let linter handle it)
- Naming style (unless it violates project naming rules)
- "I would have done it differently" without a concrete reason
- Praise-only comments ("looks good!") — save for the summary
