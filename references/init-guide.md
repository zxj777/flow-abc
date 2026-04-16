# Init Guide — Project Analysis & Rule Generation

This document guides you through initializing AI development rules for a frontend project.
You (the AI) will analyze the project, identify conventions, and generate tailored rule files.

## Prerequisites

Before starting, confirm with the user:
1. This is a frontend project they want to add AI development rules to
2. They understand that `.ai/` directory and `.github/copilot-instructions.md` will be created

## Step 1: Detect Tech Stack

Read these files to understand the project:

```
package.json          → Framework, dependencies, scripts
tsconfig.json         → TypeScript configuration
.eslintrc* / eslint.config.*  → Linting rules
.prettierrc*          → Formatting preferences
vite.config.* / next.config.* / nuxt.config.*  → Build tool & framework config
```

**Identify:**
- Framework: React / Next.js / Vue / Nuxt / Other
- Language: TypeScript / JavaScript
- Build tool: Vite / Webpack / Turbopack
- State management: Redux / Zustand / Pinia / Vuex / None
- UI library: Ant Design / Element Plus / MUI / Shadcn / Custom
- Testing: Jest / Vitest / Playwright / None
- CSS: Tailwind / CSS Modules / Styled Components / SCSS

## Step 2: Scan Project Structure

```
src/                  → Main source directory
├── components/       → Shared components
├── pages/ or views/  → Page components
├── hooks/ or composables/  → Custom hooks
├── services/ or api/ → API layer
├── stores/ or store/ → State management
├── utils/ or lib/    → Utility functions
├── types/            → TypeScript type definitions
└── assets/           → Static assets
```

**Analyze:**
- Directory structure conventions
- Component organization pattern (flat vs nested, co-located vs separated)
- Import alias patterns (check tsconfig paths or vite resolve)
- File naming conventions (PascalCase, camelCase, kebab-case)

## Step 3: Analyze Code Patterns

Read 3-5 representative files from each category to identify patterns:

**Components** (read 3-5 from components/):
- Component style: functional vs class, composition API vs options API
- Props pattern: interface definition, default values
- State management: local state, global store, context
- Styling approach: className, styled, CSS modules

**API Layer** (read services/ or api/):
- HTTP client: axios, fetch, custom wrapper
- Error handling pattern
- Request/response typing
- API organization (by domain, by method)

**Hooks / Composables** (read hooks/ or composables/):
- Naming conventions
- Return value patterns
- Common patterns used

## Step 4: Generate Rule Files

Based on your analysis, create the `.ai/` directory:

### 4.1 Create `.ai/rules/coding.md`

Generate coding rules that reflect the project's ACTUAL conventions. Reference
[rule-examples/universal.md](rule-examples/universal.md) for formatting style.

**Must include:**
- TypeScript usage rules (strict mode, any avoidance, type vs interface preference)
- Naming conventions (what you observed, not what you assume)
- Import conventions (alias paths, barrel exports, import order)
- Component patterns (the style this project actually uses)
- Error handling patterns (try/catch, Result type, error boundaries)

**Framework-specific additions:**
- React: reference [rule-examples/react.md](rule-examples/react.md)
- Vue: reference [rule-examples/vue.md](rule-examples/vue.md)

### 4.2 Create `.ai/rules/architecture.md`

**Must include:**
- API call conventions (use the project's existing wrapper, not raw fetch/axios)
- State management rules (when to use global vs local state)
- Component hierarchy (page → container → presentational boundaries)
- Directory placement rules (where new files should go)
- The adapter/VO pattern if applicable (ViewModels for UI, adapters for API transformation)

### 4.3 Create `.ai/rules/testing.md`

**Must include:**
- Test file location and naming (`*.test.ts`, `*.spec.ts`, `__tests__/`)
- Testing library and setup (what the project already uses)
- Testing strategy (unit, integration, E2E scope)
- The hybrid approach: test skeleton first → code → fill assertions

### 4.4 Create `.ai/rules/review.md`

**Must include:**
- Logic review rules (potential bugs, edge cases)
- Convention compliance (does it follow `.ai/rules/`)
- Security checks (XSS, data exposure)
- Performance checks (unnecessary re-renders, memory leaks)
- High signal-to-noise principle: only flag real issues, not style

### 4.5 Create `.ai/context/project.md`

```markdown
# Project Overview

## Tech Stack
- Framework: [detected]
- Language: [detected]
- Build: [detected]
- UI Library: [detected]
- State: [detected]
- Testing: [detected]

## Directory Structure
[summarize the actual structure]

## Key Conventions
[top 5 most important conventions you identified]
```

### 4.6 Create `.ai/context/components.md`

Scan components directory and generate an index:

```markdown
# Component Index

## Shared Components

### Button
- **Path**: `src/components/Button/index.tsx`
- **Props**: `variant`, `size`, `disabled`, `onClick`
- **Usage**: Primary actions, form submissions

### Table
- **Path**: `src/components/Table/index.tsx`
- **Props**: `columns`, `data`, `pagination`, `onSort`
- **Usage**: Data display with sorting and pagination

[... scan and list all shared components]
```

## Step 5: Compile Rules

Compile `.ai/rules/*.md` (excluding `review.md`) into `.github/copilot-instructions.md`:

```bash
# Create .github directory if needed
mkdir -p .github

# Compile: header + all rule files except review.md
echo "# AI Development Rules" > .github/copilot-instructions.md
echo "" >> .github/copilot-instructions.md
echo "<!-- Auto-generated from .ai/rules/. Edit source files, then recompile. -->" >> .github/copilot-instructions.md
echo "" >> .github/copilot-instructions.md

for f in .ai/rules/*.md; do
  if [ "$(basename "$f")" != "review.md" ]; then
    cat "$f" >> .github/copilot-instructions.md
    echo -e "\n---\n" >> .github/copilot-instructions.md
  fi
done
```

Or use the sync script: `bash <skill-scripts-path>/sync.sh`

## Step 6: Recommend Skills

Based on the detected tech stack, recommend relevant skills:

| Tech Stack | Recommended Skill |
|---|---|
| React / Next.js | `vercel-react-best-practices`, `vercel-composition-patterns` |
| UI/UX focused | `web-design-guidelines` |
| React Native | `react-native-guidelines` |

Show the install command: `npx skills add vercel-labs/agent-skills@<skill-name> -g -y`

## Step 7: Summary

After completing all steps, present a summary to the user:

```
✅ AI 开发规范初始化完成！

已创建：
  .ai/rules/coding.md        — 编码规范
  .ai/rules/architecture.md  — 架构约束
  .ai/rules/testing.md       — 测试规范
  .ai/rules/review.md        — Review 规则
  .ai/context/project.md     — 项目概述
  .ai/context/components.md  — 组件索引

已编译：
  .github/copilot-instructions.md ← 自动生效于每次 AI 对话

下一步：
  - 检查 .ai/rules/ 中的规则，按需调整
  - 编辑后运行编译更新 copilot-instructions.md
  - 将 .ai/ 和 .github/copilot-instructions.md 提交到 Git
```

---

## §Scan — Re-scan Component Index

When the user asks to rescan components:

1. Re-scan the components directory (same as Step 4.6)
2. Update `.ai/context/components.md`
3. Optionally update `.ai/context/api.md` if API files changed
4. No need to recompile `copilot-instructions.md` (context files aren't compiled)

## §Audit — Project Health Check

When the user asks for an audit:

1. Re-analyze the project (Steps 1-3)
2. Compare current code patterns against `.ai/rules/`
3. Report findings:
   - Rules that no longer match actual code patterns
   - New patterns that should be added to rules
   - Architecture improvement suggestions
4. Ask user which suggestions to adopt
5. Update `.ai/rules/` accordingly
6. Recompile `copilot-instructions.md`
