# Workflow: New Feature Development

This document guides you through the 6-stage workflow for developing a new feature or page.

## Overview

```
Step 1: Requirements → Step 2: Design (optional) → Step 3: Component Matching
→ Step 4: Coding → Step 5: Testing → Step 6: Review
```

Each step has a clear input, output, and completion signal.

---

## Step 1: Requirements Analysis

**Input**: User description, PRD document, or feature request
**Output**: Feature specification (structured understanding)

### What to do:

1. **Parse the requirement** — Extract:
   - Page structure (sections, layout hierarchy)
   - Interactive behaviors (user actions, state changes)
   - Data requirements (what data is displayed/submitted)
   - Edge cases (empty states, error states, loading states)

2. **Generate a feature specification**:

```markdown
## Feature: [Name]

### Pages / Views
- [Page name]: [description]

### Components Needed
- [Component]: [purpose]

### Data Model (ViewModel)
```typescript
interface XxxVO {
  // UI-facing data structure
}
```

### API Endpoints
- `GET /api/xxx` → list data
- `POST /api/xxx` → create item

### Adapter Layer
```typescript
// Transform API DTO → ViewModel
function adaptXxxResponse(dto: XxxDTO): XxxVO { ... }
```

### Interactions
- [Action] → [State change] → [UI update]

### Edge Cases
- Empty state: [behavior]
- Error state: [behavior]
- Loading state: [behavior]
```

3. **Present to user for confirmation**:
   - "Here's my understanding of the feature. Is this correct?"
   - Wait for user confirmation or corrections
   - This is a **checkpoint** — don't proceed without approval

4. **Ask about reference implementations**:
   After confirming the feature spec, proactively ask:

   ```
   这个需求有现成的参考实现可以借鉴吗？
   比如：其他项目写过类似功能、或者有现成的代码片段。
   没有也没关系，直接说"没有"继续。
   ```

   **Also check existing patterns** before asking:
   - Check skill-level `patterns/` directory for matching patterns
   - Check project-level `.ai/context/patterns/` for matching patterns
   - If found, show the match: "💡 找到了一个 [name] 的参考实现，要用这个吗？"

   If the user provides a reference:
   - Follow [init-guide.md §Add-Pattern](init-guide.md) to save it
   - Load it as context for the current task
   - Then continue to Step 2

   If no reference → proceed normally

### Adapter/Mock Pattern

Design the adapter layer upfront:
- Define ViewModels (VO) for UI consumption
- Define API DTOs for backend communication
- Create adapter functions that transform DTO → VO
- Start with mock data, replace with real API later (only adapter changes)

---

## Step 2: Design (Optional)

**Input**: Feature specification from Step 1
**Output**: Visual layout confirmation

### When to skip:
- The requirement already includes clear screenshots or mockups
- The feature is purely logic-based (no new UI)
- Ask the user: "Do you want a visual wireframe, or should we go straight to code?"

### When to do:
If Figma MCP is available:
1. Generate a lightweight wireframe from the specification
2. Show the user via screenshot
3. Accept natural language modifications ("move the button to the right")
4. Iterate until user says "OK"

If no Figma:
1. Describe the layout in text/ASCII
2. Confirm with user

### Completion signal: User confirms "OK" or "skip"

---

## Step 3: Component Matching

**Input**: Feature specification + component index
**Output**: Component mapping (which existing components to use)

### What to do:

1. **Read component index** — Load `.ai/context/components.md`

2. **Map UI elements to existing components**:
   - Match by semantics (button → Button, table → Table)
   - Match by layout (card grid → CardList)
   - Match by function (form input → FormField)

3. **Identify gaps** — Components that don't exist yet:
   - Mark as "new component needed"
   - Define the component spec (props, behavior)

4. **Present mapping to user**:

```markdown
## Component Mapping

### Using Existing Components:
- Header section → `PageHeader` (src/components/PageHeader)
- Data table → `DataTable` (src/components/DataTable)
- Action buttons → `Button` (src/components/Button)

### New Components Needed:
- StatusBadge: displays status with color coding
  - Props: status ('active' | 'inactive' | 'pending'), size?
```

5. **Wait for user confirmation** — This is a checkpoint

---

## Step 4: Coding

**Input**: Specification + component mapping + project rules
**Output**: Working code

### Before writing code:

1. **Load project rules** — `.github/copilot-instructions.md` is already loaded automatically
2. **Load relevant context** — Read `.ai/context/project.md` for architecture overview
3. **Check existing code** — If modifying or extending, read the current implementation first

### Coding principles:

- **Import existing components** — `import { Button } from '@/components'`, never recreate
- **Follow observed patterns** — Match the style of existing code in the project
- **Adapter layer** — Use mock data behind adapters, make it easy to swap for real API
- **Incremental approach**:
  - Read existing code structure before modifying
  - Prefer modifying existing logic over creating duplicates
  - Keep changes focused and minimal

### File creation order:
1. Types/interfaces (if new)
2. API service + adapter (with mock)
3. New shared components (if any)
4. Page/feature component
5. Route configuration (if new page)

### Completion signal: Code compiles, no TypeScript errors

---

## Step 5: Testing

**Input**: Working code from Step 4
**Output**: Tests that verify behavior

### Hybrid Testing Strategy:

#### 5a. Test Skeleton (may already exist from Step 1)

If a test skeleton was created during requirements:
```typescript
describe('UserLogin', () => {
  it('should display login form with email and password fields')
  it('should validate email format')
  it('should show error on invalid credentials')
  it('should redirect to dashboard on success')
})
```

#### 5b. Fill Test Implementation

Now that real code exists, fill in the assertions:

```typescript
describe('UserLogin', () => {
  it('should display login form with email and password fields', () => {
    render(<UserLogin />)
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
  })
  // ... fill remaining tests
})
```

#### 5c. Run Tests

- Run tests to verify they pass
- Fix any failures
- Aim for coverage of: happy path, error cases, edge cases

### If no test skeleton exists:

Write tests directly based on the specification from Step 1.

### Completion signal: All tests pass

---

## Step 6: Code Review

**Input**: Completed code + tests
**Output**: Review feedback

### Load review rules:

Read `.ai/rules/review.md` and apply the review criteria.

For detailed review process, see [review-guide.md](review-guide.md).

### Review checklist:

1. **Logic**: Potential bugs, edge cases missed?
2. **Conventions**: Follows `.ai/rules/coding.md`?
3. **Architecture**: Follows `.ai/rules/architecture.md`?
4. **Security**: XSS risks, data exposure?
5. **Performance**: Unnecessary re-renders, memory leaks?
6. **Tests**: Coverage adequate?

### High signal-to-noise principle:
- Only flag issues that genuinely matter
- Formatting issues → defer to lint
- Style preferences → defer to project conventions
- Focus on: bugs, security, performance, logic errors

### Completion signal: No critical issues, or user acknowledges findings

---

## Mid-Workflow: Adding Reference Patterns

At **any point** during the workflow, the user may say:
- "我有个参考代码"
- "等一下，我有个类似的实现"
- Or paste code directly

When this happens:
1. **Pause the current step** — remember where you are
2. Follow [init-guide.md §Add-Pattern](init-guide.md) to collect and save the pattern
3. **Load the pattern** as context for the current task
4. **Resume** from where you paused, now informed by the reference

This is not a separate workflow — it's an interrupt that can happen during any step.

---

## Summary

After completing all 6 steps, confirm with the user:

```
✅ Feature development complete!

Created:
  - [list of new/modified files]

Tests:
  - [X tests passing]

Ready for:
  - Git commit
  - PR creation
  - Human review
```
