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

你可以：
  - 纠正检测错误（如 "状态管理用的是 Jotai 不是 Zustand"）
  - 补充遗漏（如 "还用了 react-query 做数据缓存"）
  - 调整范围（如 "不需要关注测试部分"）
确认或告诉我要调整什么。
```

**Do NOT proceed until the user responds.**
- If the user provides adjustments → apply them, re-present updated results, wait again
- If the user confirms → proceed to Step 3

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

### 3.1 Deep Analysis: Global Behaviors

**This is critical.** Many projects have global-level logic that makes certain local-level
patterns unnecessary or even harmful. You MUST trace these patterns:

**Request / Response layer** — Read the request wrapper (e.g. `utils/request.ts`, `lib/http.ts`,
axios interceptors) thoroughly. Identify what is already handled globally:
- ❓ Does the interceptor already show error messages (message.error / toast)?
  → If yes: callers MUST NOT duplicate error messages
- ❓ Does it handle auth failures (401 → redirect to login)?
  → If yes: callers MUST NOT handle 401 separately
- ❓ Does it transform response format (unwrap `data` from `{ code, data, message }`)?
  → If yes: document the actual return shape callers receive
- ❓ Does it add global headers (token, locale)?
  → If yes: callers MUST NOT set these headers manually
- ❓ Does it have retry logic?
  → If yes: callers MUST NOT implement their own retry

**State management layer** — Read store setup and provider files:
- ❓ Is auth/user state managed globally?
  → If yes: components MUST NOT fetch user info independently
- ❓ Are there global loading/error states?
  → If yes: document when to use global vs local loading states

**Router / middleware layer** — Read route guards, middleware, layouts:
- ❓ Are there auth guards on routes?
  → If yes: page components MUST NOT check auth themselves
- ❓ Is there a global error boundary / fallback?
  → If yes: document what it catches and what needs local handling

**UI framework conventions** — Read theme/config setup:
- ❓ Is there a global message/notification config?
  → If yes: document the correct API to use and what NOT to call
- ❓ Are form validation rules standardized?
  → If yes: document the pattern, don't let AI reinvent it

**The principle: identify every "already handled at layer X, so don't repeat at layer Y" pattern.
These are the highest-value rules because AI WILL get them wrong without explicit guidance.**

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

你可以：
  - 增减规则文件（如 "不需要 testing.md"、"加一个 i18n.md"）
  - 调整某个文件的规则内容（如 "coding.md 里加上禁止 enum，用 as const"）
  - 修改规则严格度（如 "import 顺序改为 SHOULD 而不是 MUST"）
  - 补充项目特有约定（如 "所有 API 响应要走 adapter 转换"）
确认或告诉我要调整什么。
```

**Do NOT generate until the user responds.**
- If the user requests changes → update the plan, re-present, wait again
- If the user confirms → proceed to generate files

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

你可以：
  - 查看任意文件的完整内容（如 "看一下 coding.md"）
  - 要求修改具体规则（如 "architecture.md 里加上：禁止在组件中直接调用 localStorage"）
  - 删除某个文件（如 "去掉 testing.md，我们暂时不需要"）
  - 重新生成某个文件（如 "review.md 重新写，要更严格"）
确认或告诉我要调整什么。编译后将生效于所有 AI 对话。
```

**Do NOT compile until the user responds.**
- If the user requests changes → apply changes to the files, re-present summary, wait again
- If the user confirms → proceed to compile

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

**Supports sub-project paths.** The user may specify a sub-project:
- "clean" → clean current project root
- "clean packages/admin" → clean only `packages/admin/`
- "移除 apps/web 的 AI 规范" → clean only `apps/web/`

Determine the target root (default: project root, or user-specified sub-path).

1. Confirm with the user what to remove:

```
⚠️ 将移除以下 AI 配置（目标: <target-path>/）：

  <target>/.ai/                              — 所有规则和上下文文件
  <target>/.github/copilot-instructions.md   — 编译后的指令文件

是否保留 .github/ 目录中的其他文件（如果有）？
确认后执行移除。
```

2. **Wait for confirmation**, then:

```bash
TARGET="<target-path>"
rm -rf "$TARGET/.ai/"
rm -f "$TARGET/.github/copilot-instructions.md"
# Remove .github/ only if empty
rmdir "$TARGET/.github/" 2>/dev/null
```

3. Report result:

```
✅ 已移除 <target-path>/ 下的 AI 配置：
  - .ai/ (规则 + 上下文)
  - .github/copilot-instructions.md

AI 将不再加载该项目的特定规则。如需重新初始化，说 "初始化 AI 规范"。
```

---

## §Add-Lib — Add Library Context

When the user wants to add context for an internal or third-party library:

**Triggers**: "添加 xxx 的上下文", "Add context for xxx", or mid-workflow when AI encounters an unfamiliar library.

### Steps:

1. **Identify the library** — From user's mention or from import statements in code.

2. **Gather information** — Try these sources in order:
   - `node_modules/<package>/` — Read type definitions (`.d.ts`), README, package.json
   - Project code — Search for existing usage patterns (`grep` for imports)
   - User input — Ask the user to describe the API or paste key type definitions

3. **Generate context file** — Write to `.ai/context/libs/<name>.md`:

```markdown
# <Library Name>

> Source: <internal package / npm / user-provided>

## Key APIs

### functionName(params): ReturnType
- Purpose: [what it does]
- Example:
```typescript
const result = functionName({ key: 'value' })
```

## Usage Conventions in This Project
- [How this project typically uses the library]
- [Any wrappers or abstractions on top]

## Gotchas
- [Common mistakes or things AI should avoid]
```

4. **Confirm with user**:

```
📚 已生成库上下文: .ai/context/libs/<name>.md

包含:
  - N 个关键 API
  - 项目中的使用惯例
  - N 条注意事项

请检查内容是否准确，需要调整告诉我。
```

**Important**: This file is NOT compiled into `copilot-instructions.md`. It is loaded on demand
when a workflow involves this library.

### Updating existing lib context

If `.ai/context/libs/<name>.md` already exists, show the user the current version and ask:
- Overwrite (重新生成)
- Append new content (追加)
- Cancel

---

## §Add-Pattern — Add Reference Implementation

When the user has a working code example they want AI to reference for future development.

**Triggers**:
- Standalone: "加个参考实现", "Add reference pattern"
- During workflow Step 1: User answers "yes" when asked about reference implementations
- Mid-workflow: User interrupts with "我有个参考代码" or pastes code

### Two sources:

**A. User provides code directly** (paste or file path):

1. User pastes code or points to a file
2. AI reads and understands the code
3. AI generates a pattern file with annotations

**B. From another project** (user describes the location):

1. User says "我在 xxx 项目有个 Excel 导出的实现"
2. AI asks: "能粘贴关键代码，或者告诉我文件路径吗？"
3. User provides the code
4. AI generates a pattern file

### Pattern file format:

Write to `.ai/context/patterns/<name>.md`:

```markdown
# Pattern: <Name>

> 用途: [what this pattern solves]
> 来源: [where it came from — user-provided / project-name / etc.]

## Reference Implementation

```typescript
// The actual working code, with comments explaining key decisions
export async function exportToExcel(data: ExportData[], options: ExportOptions) {
  const workbook = new ExcelJS.Workbook()
  const sheet = workbook.addWorksheet(options.sheetName)

  // Set column definitions from options
  sheet.columns = options.columns.map(col => ({
    header: col.label,
    key: col.key,
    width: col.width ?? 20,
  }))

  // Add data rows
  data.forEach(row => sheet.addRow(row))

  // Style header row
  sheet.getRow(1).font = { bold: true }

  // Generate and download
  const buffer = await workbook.xlsx.writeBuffer()
  downloadBlob(buffer, `${options.fileName}.xlsx`, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
}
```

## Adaptation Notes

When using this pattern in current project:
- [What to keep as-is]
- [What to adapt to current project conventions]
- [Dependencies needed: e.g., `npm install exceljs`]

## Key Decisions

- [Why this approach over alternatives]
- [Performance considerations]
- [Edge cases handled]
```

### Steps:

1. **Collect** — Get the code from user (paste, file path, or description)

2. **Understand** — Identify what the pattern does, key decisions, dependencies

3. **Generate** — Write `.ai/context/patterns/<name>.md` in the format above

4. **If mid-workflow** — Immediately load the pattern as context for the current task:
   ```
   📝 已保存参考实现: .ai/context/patterns/<name>.md
   已加载为当前任务的上下文，继续开发...
   ```

5. **If standalone** — Confirm:
   ```
   📝 已保存参考实现: .ai/context/patterns/<name>.md

   AI 在后续开发涉及 [相关功能] 时会自动参考此实现。
   该文件不会编译到 copilot-instructions.md，仅按需加载。
   ```

**Important**: Pattern files are NOT compiled. They are loaded on demand when AI determines
the current task relates to the pattern's purpose.

### Also check skill-level patterns

Before asking the user to provide code, check if `patterns/` directory in this skill repo
already has a matching pattern. If found, show it to the user:

```
💡 flow-abc 自带了一个 [pattern-name] 的参考实现，要直接用这个吗？
还是你有自己项目的版本？
```

### Push to skill repo (share across all projects)

After saving a project-level pattern, ask the user:

```
这个 pattern 要推送到 flow-abc skill 仓库，共享给所有项目吗？
```

If the user confirms, push automatically using the repository info from SKILL.md metadata:

```bash
SKILL_REPO="<repository from SKILL.md metadata>"  # e.g. zxj777/flow-abc
PATTERN_FILE=".ai/context/patterns/<name>.md"
PATTERN_NAME="<name>"
TEMP_DIR=$(mktemp -d)

# Clone, copy, commit, push
gh repo clone "$SKILL_REPO" "$TEMP_DIR" -- --depth 1
mkdir -p "$TEMP_DIR/patterns"
cp "$PATTERN_FILE" "$TEMP_DIR/patterns/$PATTERN_NAME.md"
cd "$TEMP_DIR"
git add "patterns/$PATTERN_NAME.md"
git commit -m "feat(patterns): add $PATTERN_NAME"
git push origin main

# Cleanup
rm -rf "$TEMP_DIR"
```

Then report:

```
✅ 已推送到 skill 仓库: patterns/<name>.md
所有使用 flow-abc skill 的项目更新后即可共享此参考实现。
```

If push fails (no permission, network error), fall back gracefully:

```
⚠️ 推送失败: <error>
pattern 已保存在本项目: .ai/context/patterns/<name>.md
你可以手动推送到 skill 仓库，或稍后重试。
```
