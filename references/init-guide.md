# Init Guide — Project Analysis & Rule Generation

This document guides you through initializing AI development rules for a frontend project.
You (the AI) will analyze the project, identify conventions, and generate tailored rule files.

**Key principle: Confirm at every major step.** Don't generate silently — present findings
and get user approval before proceeding.

## Prerequisites

Before starting, confirm with the user:
1. This is a frontend project they want to add AI development rules to
2. They understand that `.ai/` directory and `.github/copilot-instructions.md` will be created

## Step 0: Detect Project Type

Determine if this is a single-project repo or a monorepo:

**Monorepo indicators:**
- Root `package.json` has `workspaces` field
- `pnpm-workspace.yaml` exists
- `lerna.json` exists
- Multiple `package.json` files in `apps/`, `packages/`, or similar directories
- `turbo.json` or `nx.json` exists

**If monorepo detected:**
1. List all sub-projects (directories with their own `package.json`)
2. Ask the user which sub-projects to initialize (or all)
3. For each sub-project, detect tech stack independently
4. Shared rules go in `.ai/`, sub-project rules go in `.ai-<name>/`
5. Compilation produces both `.github/copilot-instructions.md` (shared) and `.github/instructions/<name>.instructions.md` (per sub-project)

**If single-project:** proceed to Step 1 as normal.

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

### ✅ Checkpoint 1: Confirm Detection Results

Present findings to the user in this format and **wait for confirmation**:

```
🔍 项目检测结果：

技术栈：
  - 框架: React 18 + Next.js 14 (App Router)
  - 语言: TypeScript (strict mode)
  - 构建: Turbopack
  - 状态管理: Zustand
  - UI 库: Shadcn/ui + Tailwind CSS
  - 测试: Vitest + Playwright
  - CSS: Tailwind CSS + CSS Modules

项目结构：
  - 组件目录: src/components/ (flat structure)
  - 页面目录: src/app/ (App Router)
  - Hooks: src/hooks/
  - API 层: src/services/ (axios wrapper)
  - 文件命名: PascalCase for components, camelCase for utils

检测有误或需要补充吗？确认后我将分析代码模式。
```

**Do NOT proceed until the user confirms.** If they correct something, update your findings.

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

Based on your analysis, generate the rule files. **Present each file's key content
to the user for review before writing.**

### ✅ Checkpoint 2: Confirm Rule Plan

Before generating files, show the user what rules you plan to create:

```
📋 将生成以下规则文件：

1. .ai/rules/coding.md — 编码规范
   - TypeScript strict, 禁止 any
   - 命名: PascalCase 组件, camelCase 函数
   - Import 顺序: React → 三方 → @/ → 相对 → 样式
   - Props 使用 interface 定义并导出

2. .ai/rules/architecture.md — 架构约束
   - API 调用统一使用 src/services/ 的 request wrapper
   - 状态分层: useState → Zustand → Context
   - 组件层级: page → container → presentational

3. .ai/rules/testing.md — 测试规范
   - 单元测试: Vitest, *.test.ts
   - E2E: Playwright, tests/*.spec.ts
   - 测试骨架先行模式

4. .ai/rules/review.md — Review 规则
   - 5 维度检查（逻辑/规范/安全/性能/架构）

5. .ai/context/project.md — 项目概述
6. .ai/context/components.md — 组件索引 (N 个组件)

需要调整、增删吗？确认后开始生成。
```

**Do NOT generate until the user confirms.** Adjust the plan based on feedback.

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

### ✅ Checkpoint 3: Confirm Before Compile

After generating all files, present a summary and **wait for confirmation** before compiling:

```
✅ 规则文件已生成，请检查：

  .ai/rules/coding.md        — 编码规范 (XX 条规则)
  .ai/rules/architecture.md  — 架构约束
  .ai/rules/testing.md       — 测试规范
  .ai/rules/review.md        — Review 规则
  .ai/context/project.md     — 项目概述
  .ai/context/components.md  — 组件索引 (N 个组件)

你可以查看任意文件内容，提出修改意见。
确认后我将编译 → .github/copilot-instructions.md
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

### Monorepo: Compile Path-Specific Instructions

For each sub-project `.ai-<name>/`, compile into `.github/instructions/<name>.instructions.md`:

```bash
mkdir -p .github/instructions

# For each sub-project config directory
for sub_dir in .ai-*/; do
  [ -d "$sub_dir/rules" ] || continue
  NAME="${sub_dir#.ai-}"
  NAME="${NAME%/}"

  # Detect the applyTo path from .ai-<name>/applyTo (single line with glob)
  APPLY_TO="**"
  if [ -f "$sub_dir/applyTo" ]; then
    APPLY_TO=$(cat "$sub_dir/applyTo")
  fi

  OUTPUT=".github/instructions/${NAME}.instructions.md"

  # Write frontmatter
  cat > "$OUTPUT" << EOF
---
applyTo: "$APPLY_TO"
---

<!-- Auto-generated from .ai-${NAME}/rules/. Edit source files, then recompile. -->

EOF

  # Append all rules except review.md
  for f in "$sub_dir/rules/"*.md; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "review.md" ] && continue
    cat "$f" >> "$OUTPUT"
    echo -e "\n---\n" >> "$OUTPUT"
  done
done
```

Each sub-project directory should contain an `applyTo` file with the glob pattern, e.g.:
```
# .ai-web/applyTo
apps/web/**
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

For monorepo, additionally show:

```
Monorepo 子项目规则：
  .ai-<name>/rules/         — <name> 专属规则
  .ai-<name>/applyTo        — 路径匹配: apps/<name>/**

已编译路径指令：
  .github/instructions/<name>.instructions.md ← 编辑 apps/<name>/ 时自动生效
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

## §Clean — Remove AI Config

When the user asks to remove AI config / clean / 移除规范:

1. Confirm with the user what to remove:

```
⚠️ 将移除以下 AI 配置：

  .ai/                              — 所有规则和上下文文件
  .github/copilot-instructions.md   — 编译后的指令文件

是否保留 .github/ 目录中的其他文件（如果有）？
确认后执行移除。
```

2. **Wait for confirmation**, then:

```bash
rm -rf .ai/
rm -f .github/copilot-instructions.md
# Remove .github/ only if empty
rmdir .github/ 2>/dev/null
```

3. Report result:

```
✅ 已移除：
  - .ai/ (规则 + 上下文)
  - .github/copilot-instructions.md

AI 将不再加载项目特定规则。如需重新初始化，说 "初始化 AI 规范"。
```
