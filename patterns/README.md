# Shared Patterns

This directory contains **reference implementations** shared across all projects using the flow-abc skill.

## How it works

- AI checks this directory when a workflow involves functionality that might have a reference pattern
- Patterns are loaded **on demand**, not compiled into `copilot-instructions.md`
- These are **cross-project** patterns; project-specific patterns go in `.ai/context/patterns/`

## File format

Each pattern file should follow this structure:

```markdown
# Pattern: <Name>

> 用途: [what this pattern solves]
> 依赖: [npm packages needed, if any]

## Reference Implementation

[Working code with explanatory comments]

## Adaptation Notes

- [What to keep as-is]
- [What to adapt to project conventions]
- [Dependencies to install]

## Key Decisions

- [Why this approach]
- [Edge cases handled]
```

## Contributing

When you create a project-level pattern (`.ai/context/patterns/`) that's broadly useful,
you can push it here by telling AI: "推送这个 pattern 到 skill 仓库".
