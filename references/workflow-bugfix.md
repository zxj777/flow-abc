# Workflow: Bug Fix

This document guides you through fixing a bug systematically.

## Overview

```
Step 1: Reproduce → Step 2: Locate → Step 3: Root Cause → Step 4: Fix
→ Step 5: Verify → Step 6: Review
```

---

## Step 1: Reproduce / Understand the Bug

**Input**: Bug report from user
**Output**: Clear understanding of expected vs actual behavior

### Gather information:

1. **What is the expected behavior?**
2. **What is the actual behavior?**
3. **Steps to reproduce** (if applicable)
4. **Error messages** (if any — check console, terminal, logs)
5. **Environment** (browser, Node version, build mode)

### If information is insufficient:

Ask the user to clarify:
- "Can you describe the expected behavior?"
- "Is there an error message in the console?"
- "Does this happen consistently or intermittently?"

### Completion signal: Clear understanding of the bug

---

## Step 2: Locate the Bug

**Input**: Bug understanding
**Output**: Identified code location

### Search strategies:

1. **Error-driven**: If there's an error message, search for:
   - The error text in source code
   - The stack trace file/line references
   - The error type or code

2. **Behavior-driven**: If no error, trace the data flow:
   - Identify the UI element or behavior that's wrong
   - Find the component that renders it
   - Trace the data source (props → hooks → API → adapter)

3. **Recent change-driven**: If "it was working before":
   - Check recent git commits
   - Look at recently modified files related to the feature

### Read the identified code carefully

---

## Step 3: Root Cause Analysis

**Input**: Located code
**Output**: Understanding of WHY the bug occurs

### Common root causes:

- **Type mismatch**: API returns different shape than expected
- **Null/undefined**: Missing null checks or optional chaining
- **State timing**: Race conditions, stale closures, effect ordering
- **Logic error**: Wrong condition, off-by-one, incorrect comparison
- **Missing handling**: Unhandled edge case (empty array, empty string, 0)

### Explain to user:

```
Root cause: The `useUserList` hook doesn't handle the case where the API
returns an empty `data` field (null instead of []). The `.map()` call on
line 23 throws "Cannot read property 'map' of null".
```

### Completion signal: Root cause identified and confirmed

---

## Step 4: Fix

**Input**: Root cause understanding
**Output**: Code fix

### Fix principles:

- **Fix the root cause**, not the symptom
- **Minimal change** — Don't refactor surrounding code
- **Defensive** — Add guards that prevent the same category of bug
- **Follow patterns** — Use the same error handling style as the rest of the code

### Example fix:

```typescript
// Before (bug)
const users = data.map(item => adaptUser(item))

// After (fix)
const users = (data ?? []).map(item => adaptUser(item))
```

---

## Step 5: Verify

**Input**: Fixed code
**Output**: Verified fix

### Verification steps:

1. **Write a test** that reproduces the bug:
   ```typescript
   it('should handle null data from API', () => {
     // Mock API returning null data
     // Verify component renders empty state (not crash)
   })
   ```

2. **Run the test** — It should pass with the fix

3. **Run all related tests** — Ensure no regressions

4. **If possible, test manually** — Verify the original bug is fixed

### Completion signal: Bug is fixed and verified

---

## Step 6: Review

**Input**: Fix + test
**Output**: Review confirmation

### Bug fix review focus:

1. **Root cause addressed** — Not just a band-aid
2. **No regressions** — Other functionality still works
3. **Test coverage** — The specific bug has a regression test
4. **Similar patterns** — Are there similar bugs elsewhere? (Don't fix them now, but note them)

### Completion signal: Fix is clean and complete

---

## Summary

```
✅ Bug fix complete!

Bug: [description]
Root cause: [explanation]
Fix: [what was changed]

Modified:
  - [file]: [what changed]

Tests:
  - Added regression test for [bug description]
  - All [X] tests passing
```
