# Workflow: Modify Existing Feature

This document guides you through modifying an existing feature or page.

## Overview

```
Step 1: Locate → Step 2: Understand → Step 3: Plan → Step 4: Implement
→ Step 5: Test → Step 6: Review
```

This workflow is simpler than new feature development because the code already exists.

---

## Step 1: Locate Existing Code

**Input**: User's description of what to modify
**Output**: Identified files and code sections

### How to locate:

1. **Extract keywords** from the user's request (page name, feature name, route)

2. **Search strategies** (try in order):
   - Route configuration: search for route paths or page names
   - Component names: grep for the feature/page component
   - File names: glob for likely file names
   - Text content: search for visible UI text mentioned by user

3. **If uncertain**: Present candidates to the user
   ```
   I found these potentially related files:
   1. src/pages/UserList/index.tsx (route: /users)
   2. src/components/UserCard.tsx
   3. src/services/userApi.ts
   
   Which ones are relevant to your change?
   ```

4. **Read the identified files** to understand current implementation

### Completion signal: User confirms the correct files are identified

---

## Step 2: Understand Current Implementation

**Input**: Located files
**Output**: Understanding of current code structure

### What to analyze:

1. **Component structure** — How is the component organized? What are the sub-components?
2. **State management** — What state exists? Local or global? How is it updated?
3. **Data flow** — Where does data come from? How is it transformed?
4. **Side effects** — What API calls, subscriptions, or effects exist?
5. **Tests** — Do tests exist? What do they cover?

### Present your understanding:

```
Current implementation:
- UserList page renders a table of users via `useUserList()` hook
- Data flows: API → adapter → UserVO[] → table component
- Filtering is done client-side with useMemo
- No tests exist currently

Your requested change: add server-side filtering
```

### Completion signal: User confirms your understanding is correct

---

## Step 3: Plan Changes

**Input**: Understanding + modification request
**Output**: Change plan

### Create a change plan:

```markdown
## Change Plan

### Files to modify:
1. `src/services/userApi.ts` — Add filter parameters to API call
2. `src/hooks/useUserList.ts` — Pass filter params, remove client-side filtering
3. `src/pages/UserList/index.tsx` — Add filter UI components

### Files to create:
- None (or list new files if needed)

### Impact analysis:
- UserList page: direct change
- UserCard component: no impact
- Other pages using useUserList: need to verify no breaking changes
```

### Wait for user confirmation

---

## Step 4: Implement

**Input**: Approved change plan
**Output**: Modified code

### Implementation principles:

- **Read before writing** — Always re-read the file before making changes
- **Minimal changes** — Only modify what's needed for the feature
- **Preserve patterns** — Follow the existing code style in the file
- **Don't refactor unrelated code** — Unless explicitly asked
- **Update imports** — If adding new dependencies, follow existing import patterns

### Incremental approach:

1. Make changes to API/service layer first
2. Update hooks/composables
3. Update components
4. Update types if needed

### Completion signal: Code compiles, no TypeScript errors

---

## Step 5: Test

**Input**: Modified code
**Output**: Updated tests

### Test approach:

1. **If tests exist**: Update them to cover the new behavior
2. **If no tests exist**: Write tests for the modified functionality
3. **Run all related tests** to ensure no regressions

### Verify:
- The new behavior works as expected
- Existing behavior is not broken
- Edge cases are handled

### Completion signal: All tests pass

---

## Step 6: Review

**Input**: All changes
**Output**: Review feedback

### Focus areas for modification review:

1. **No unintended side effects** — Changes don't break other features
2. **Backward compatibility** — Existing usage still works
3. **Consistent patterns** — Changes follow the same patterns as existing code
4. **Complete changes** — Nothing was missed (types, tests, imports)

Read `.ai/rules/review.md` for detailed review rules.

### Completion signal: No critical issues found

---

## Summary

```
✅ Feature modification complete!

Modified:
  - [list of modified files]

Created:
  - [list of new files, if any]

Tests:
  - [X tests passing, Y new tests added]

Impact:
  - [summary of impact on other parts of codebase]
```
