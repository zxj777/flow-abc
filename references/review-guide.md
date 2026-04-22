# Review Guide — AI Code Review Rules

This document defines how to perform code review as an AI assistant.

## Step 0: Load Project Review Rules (REQUIRED)

Before starting the review, check if the project has custom review rules:

1. Look for `.ai/rules/review.md` in the project root
2. If it exists, **read it first** — it contains project-specific review criteria that must be applied
3. If it doesn't exist, proceed with the general criteria below

> Project-specific rules in `.ai/rules/review.md` take precedence over the general guidelines in this document.

---

## Core Principle: High Signal-to-Noise Ratio

**Only flag issues that genuinely matter.** The goal is to catch real problems, not to nitpick.

### DO flag:
- Bugs and logic errors
- Security vulnerabilities
- Performance issues with real impact
- Missing error handling that could cause crashes
- Architecture violations that will cause maintenance pain

### DON'T flag:
- Formatting (that's what Prettier/ESLint are for)
- Style preferences (use project conventions, not personal taste)
- Minor naming suggestions (unless genuinely confusing)
- "I would have done it differently" (unless the current approach has real problems)

---

## Review Dimensions

### 1. Logic Review

Check for:
- **Null/undefined risks**: Missing optional chaining, null checks
- **Off-by-one errors**: Loop boundaries, array indices
- **Race conditions**: Concurrent state updates, stale closures
- **Edge cases**: Empty arrays, empty strings, zero values, very large inputs
- **Type safety**: `any` usage, unsafe type assertions, missing type narrowing
- **Boolean logic**: Incorrect conditions, missing negation, wrong operator precedence

### 2. Convention Review

Check against `.ai/rules/`:
- **Naming conventions**: Does it follow the project's naming patterns?
- **Import conventions**: Correct alias paths, import order?
- **Component patterns**: Follows the project's component style?
- **API patterns**: Uses the project's API wrapper, not raw fetch/axios?
- **State patterns**: Correct use of global vs local state?
- **File placement**: In the correct directory?

### 3. Security Review

Check for:
- **XSS**: `dangerouslySetInnerHTML`, unescaped user input in DOM
- **Injection**: Unsanitized data in SQL, URLs, shell commands
- **Data exposure**: Sensitive data in console.log, error messages, client bundles
- **Auth**: Missing auth checks, exposed API keys
- **CSRF**: Missing CSRF tokens on state-changing requests

### 4. Performance Review

Check for:
- **Unnecessary re-renders**: Missing memo/useMemo/useCallback where it matters
- **Large bundle impact**: Importing entire libraries (lodash vs lodash/get)
- **Memory leaks**: Missing cleanup in useEffect, event listeners
- **Network waterfalls**: Sequential API calls that could be parallel
- **Large data**: Rendering large lists without virtualization

### 5. Architecture Review

Check for:
- **Separation of concerns**: Business logic in UI components?
- **Coupling**: Tight coupling between unrelated modules?
- **Duplication**: Duplicated logic that should be extracted?
- **Adapter pattern**: Direct API shape in UI instead of ViewModels?

---

## Review Output Format

Present findings organized by severity:

```markdown
## Code Review

### 🔴 Critical (must fix)
- **[file:line]**: [issue description]
  - Why: [explanation of impact]
  - Suggestion: [how to fix]

### 🟡 Warning (should fix)
- **[file:line]**: [issue description]
  - Why: [explanation]
  - Suggestion: [how to fix]

### 💡 Suggestion (nice to have)
- **[file:line]**: [suggestion]
```

### Severity guidelines:

- **🔴 Critical**: Bugs, security vulnerabilities, data loss risks, crashes
- **🟡 Warning**: Performance issues, missing error handling, convention violations with real impact
- **💡 Suggestion**: Minor improvements, refactoring opportunities

### If no issues found:

```
✅ Code review passed — no significant issues found.

The code follows project conventions, handles errors appropriately, and has no
obvious security or performance concerns.
```

---

## Review Scope

### What to review:
- All new and modified code
- Test coverage for new functionality
- Import changes and dependency additions
- Configuration changes

### What NOT to review:
- Auto-generated code (unless it looks wrong)
- Third-party library code
- Unrelated code in the same file (unless it's clearly broken)

---

## Self-Review Integration

When following a development workflow (new feature, modify, bugfix), perform a
lightweight self-review at the end of Step 6 using these criteria.

This is NOT a replacement for human review — it's a pre-filter to catch obvious
issues before the code reaches a human reviewer.
