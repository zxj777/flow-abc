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

## Step 1: Full Inventory (List Everything, Read Nothing)

**First, get a complete picture of the project.** Run a recursive file listing of the entire
source tree. Do NOT read file contents yet — only collect paths.

```bash
# List all source files (exclude node_modules, dist, .git, etc.)
find . -type f \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  -not -path '*/.next/*' \
  -not -path '*/.nuxt/*' \
  -not -path '*/coverage/*' \
  | sort
```

**From this file list, identify:**

- **Project scale** — How many source files? (50 files vs 500 files → different strategies)
- **Directory structure** — What are the top-level directories under `src/`?
- **Module boundaries** — Are there clear domain folders (e.g., `modules/user/`, `features/auth/`)?
- **File naming patterns** — PascalCase / camelCase / kebab-case (observable from paths alone)
- **Co-location patterns** — Are tests, styles, types next to components or in separate trees?
- **Key infrastructure files** — Spot files like `request.ts`, `http.ts`, `auth.ts`, `router.ts`,
  `store/index.ts`, `middleware.ts`, `App.tsx`, `main.tsx`

**This inventory is the foundation for all subsequent reads.** Don't skip it.

## Step 2: Config & Entry Point Reads (Must-Read Files)

Now read file contents, starting with the highest-signal files.

### 2.1 Config Files (tech stack detection)

```
package.json          → Framework, dependencies, scripts
tsconfig.json         → TypeScript configuration, path aliases
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

### 2.2 Entry Points (architecture skeleton)

Read the application entry and top-level wiring files:

- **App entry**: `main.tsx` / `main.ts` / `App.tsx` / `App.vue`
- **Router config**: `router/index.ts`, `app/layout.tsx`, route definitions
- **Store setup**: `store/index.ts`, provider wrappers, context providers
- **Global styles/theme**: theme config, global CSS entry

These files reveal the application's **top-level architecture** — how routing, state, and
rendering are wired together.

### 2.3 Infrastructure Files (global behaviors — CRITICAL)

**This is the highest-value read.** Many projects have global-level logic that makes certain
local-level patterns unnecessary or even harmful. You MUST find and read these files thoroughly.

Use the file inventory from Step 1 to locate them. Common locations:

**Request / Response layer** — e.g. `utils/request.ts`, `lib/http.ts`, `api/client.ts`,
axios instance files, fetch wrappers.

**You MUST read the actual implementation, not just know the file exists.**
For each question, write down the concrete answer (not just "yes/no"):

- ❓ Does the interceptor already show error messages (message.error / toast)?
  → If yes: **write down the exact code** (e.g., `message.error(res.data.message)` in response
  interceptor). Callers MUST NOT duplicate error messages.
- ❓ Does it handle auth failures (401 → redirect to login)?
  → If yes: **write down the mechanism** (e.g., "401 triggers `store.dispatch(redirectToLogin())`
  which navigates to /login"). Callers MUST NOT handle 401 separately.
- ❓ Does it transform response format?
  → **Write down what callers actually receive.** E.g., backend returns `{ code, data, message }`,
  interceptor unwraps to `data` only → callers get the inner data directly. Or: interceptor
  does NOT unwrap → callers get the full envelope.
- ❓ Does it add global headers (token, locale, custom headers)?
  → If yes: **list which headers** (e.g., `Authorization: Bearer ${token}`, `gId: xxx`).
  Callers MUST NOT set these headers manually.
- ❓ Does it have retry logic, timeout config, or base URL patterns?
  → **Write down the specifics** (e.g., "timeout 30s, no retry, base URL from
  `appRequest('/user-service')` which prepends `/api/user-service`").
- ❓ How are request instances created?
  → **Document the factory pattern** if there is one (e.g., `appRequest('/svc-name')` returns
  an axios instance scoped to that microservice). This determines how callers should create
  new service files.

**State management layer** — store setup and provider files:
- ❓ Is auth/user state managed globally?
  → If yes: **write down the store name, key fields, and how components access it**
  (e.g., `useSelector(state => state.app.userInfo)`). Components MUST NOT fetch user
  info independently.
- ❓ Are there global loading/error states?
  → If yes: **write down when to use global vs local** (e.g., "global loading only for
  route transitions; page-level loading uses ahooks `useRequest({ loading })`").
- ❓ What events/actions flow through the store?
  → **List all actions** (e.g., `redirectToLogin`, `logout`, `openChangePassword`).
  Document what triggers them and what effect they have.

**Router / middleware layer** — route guards, middleware, layouts:
- ❓ Are there auth guards on routes?
  → If yes: **write down the guard chain** (e.g., `Authenticated → AccessControlProvider
  → PermissionGuard`). Document what each layer checks. Page components MUST NOT
  check auth themselves.
- ❓ Is there a global error boundary / fallback?
  → If yes: **write down what it catches** and what still needs local handling.
- ❓ How is route config structured?
  → **Document the pattern** (e.g., "flat array in router/index.tsx" or "file-based routing"
  or "nested route objects with lazy loading").

**UI framework conventions** — theme/config setup:
- ❓ Is there a global message/notification config?
  → If yes: **write down the config** (e.g., `message.config({ maxCount: 1 })` in App.tsx).
  Document the correct API to use and what NOT to call.
- ❓ Is there a global theme / responsive strategy?
  → **Write down the specifics** (e.g., "Emotion Global: `html { fontSize: calc(100 * 100vw
  / 1920) }` → all rem values are relative to 1920px design"). This affects every
  component's sizing.
- ❓ Are form validation rules standardized?
  → If yes: **write down where** (e.g., `utils/validators.ts` exports `phoneRule`,
  `emailRule`). Don't let AI reinvent them.

**CSS / styling patterns** — how styles are written:
- ❓ What's the primary styling approach?
  → **Write down which method is dominant** (e.g., "Emotion `css` prop for custom styles,
  Ant Design component props for standard UI, no styled-components"). Include an example
  of the typical pattern.
- ❓ Are there shared style tokens / variables?
  → **List them** (e.g., theme colors in `theme.ts`, spacing constants, shared mixins).

**The principle: for every global behavior, write down the CONCRETE mechanism, not just
"it exists". The checkpoint output must contain enough detail that a developer reading it
can immediately know what NOT to do and WHY.**

### ✅ Checkpoint 1: Confirm Detection Results

Present findings to the user in this format and **wait for confirmation**:

```
🔍 项目检测结果：

项目规模：N 个源文件（按类型: X tsx + Y ts + Z css + ...）

技术栈：
  - 框架: React 18 + Next.js 14 (App Router)
  - 语言: TypeScript (strict mode)
  - 构建: Turbopack
  - 状态管理: Zustand
  - UI 库: Shadcn/ui + Tailwind CSS
  - 测试: Vitest + Playwright
  - CSS: Tailwind CSS + CSS Modules

项目结构：
  - 组件目录: src/components/ (flat structure, N 个组件)
  - 页面目录: src/app/ (App Router, N 个页面)
  - Hooks: src/hooks/ (N 个)
  - API 层: src/services/ (axios wrapper)
  - 文件命名: PascalCase for components, camelCase for utils

全局行为（⚠️ 必须写出具体机制，不能只写"有"）：

  📡 请求层:
    - 实例创建: appRequest('/svc-name') → 生成 baseURL 为 /api/svc-name 的 axios 实例
    - 响应处理: interceptor 检查 res.data.code，非 0 时 message.error(res.data.message)
    - 认证失败: 401 → store.dispatch(redirectToLogin()) → 跳转 /login
    - Response 形状: interceptor unwrap 到 res.data.data，调用方拿到的是内层 data
    - 全局 Headers: Authorization + gId（从 context 注入）
    - ⛔ 禁止: 调用方不要重复 toast、不要自己处理 401、不要手动加 token

  🗄️ 状态层:
    - Redux 仅做全局事件分发: redirectToLogin / logout / openChangePassword
    - 业务数据: ahooks useRequest / usePagination + 组件 state，不走 Redux
    - ⛔ 禁止: 不要把页面业务数据放进 Redux

  🔐 路由层:
    - 守卫链: Authenticated → AccessControlProvider → PermissionGuard
    - Authenticated: 检查 token 存在性
    - AccessControlProvider: 加载权限数据
    - PermissionGuard: 按路由配置检查具体权限
    - ⛔ 禁止: 页面组件不要自己检查登录态或权限

  🎨 UI / 样式层:
    - Ant Design ConfigProvider: zh_CN locale + message.config({ maxCount: 1 })
    - 响应式: Emotion Global html { fontSize: calc(100 * 100vw / 1920) }
    - 样式写法: Emotion css prop 为主，Ant Design 组件 props 控制 UI 状态
    - ⛔ 禁止: 不要用 inline style 对象，不要引入新的 CSS 方案

你可以：
  - 纠正检测错误（如 "状态管理用的是 Jotai 不是 Zustand"）
  - 补充遗漏（如 "还用了 react-query 做数据缓存"）
  - 调整范围（如 "不需要关注测试部分"）
  - 补充全局行为（如 "表单校验也有统一封装在 utils/validator.ts"）
确认或告诉我要调整什么。
```

**Do NOT proceed until the user responds.**
- If the user provides adjustments → apply them, re-present updated results, wait again
- If the user confirms → proceed to Step 3

## Step 3: Strategic Code Sampling

Based on the inventory (Step 1) and infrastructure reads (Step 2), now read representative
source files to identify coding patterns. **Don't read randomly — pick strategically.**

### 3.1 Components (read from components/)

**Selection strategy:**
- Pick 1 **simple** component (few props, no state) — to see the baseline pattern
- Pick 1 **complex** component (many props, local state, side effects) — to see the full pattern
- Pick 1 **most-imported** component (referenced by many other files) — to see the common interface
- If the project has both shared components and feature-specific components, sample from each

**What to observe:**
- Component style: functional vs class, composition API vs options API
- Props pattern: interface definition, default values, required vs optional
- State management: local state, global store, context
- Styling approach: className, styled, CSS modules, Tailwind

### 3.2 Pages (read 1-2 complete pages)

**Selection strategy:**
- Pick 1 **data-driven page** (table/list with API calls, filtering, pagination)
- Pick 1 **form page** (create/edit with validation, submission)

**What to observe — trace the full data flow:**
- How is data fetched? (hook → service → adapter → component)
- How is state managed on the page? (local vs global)
- How are errors handled at the page level?
- How is the page composed from smaller components?

### 3.3 API / Service Layer (read 2-3 service files)

**Selection strategy:**
- Pick services from 2 different business domains (e.g., `userService` + `orderService`)
- If there's an adapter/transform layer, read at least 1 adapter file

**What to observe:**
- API organization (by domain, by method, flat vs nested)
- Request/response typing patterns
- How DTOs are transformed to ViewModels (if applicable)
- Error handling at the service level (vs. what the global interceptor already does)

### 3.4 Hooks / Composables (read 2-3 most-used)

**Selection strategy:**
- From the inventory, pick hooks that are imported by the most files
- Include at least 1 data-fetching hook and 1 UI/behavior hook

**What to observe:**
- Naming conventions (useXxx / useXxxQuery / useXxxMutation)
- Return value patterns (tuple vs object vs single value)
- How they compose with other hooks

### 3.5 Tests (if testing files exist, read 1-2)

**What to observe:**
- Test file location pattern (co-located vs `__tests__/` vs `tests/`)
- Testing library and utilities used
- Test naming and organization style
- What gets tested (behavior vs implementation)

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

If the user confirms, push automatically. Use the actual repository value from this skill's
`SKILL.md` metadata (`repository: "zxj777/flow-abc"`), then run the whole block as one shell session:

```bash
set -euo pipefail

SKILL_REPO="zxj777/flow-abc"
PATTERN_NAME="<actual-pattern-name>"
PATTERN_FILE=".ai/context/patterns/${PATTERN_NAME}.md"
TEMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

if [ ! -f "$PATTERN_FILE" ]; then
  echo "Pattern file not found: $PATTERN_FILE" >&2
  exit 1
fi

gh repo clone "$SKILL_REPO" "$TEMP_DIR" -- --depth 1
mkdir -p "$TEMP_DIR/patterns"
cp "$PATTERN_FILE" "$TEMP_DIR/patterns/$PATTERN_NAME.md"

cd "$TEMP_DIR"
git add "patterns/$PATTERN_NAME.md"

if git diff --cached --quiet; then
  echo "Pattern already synced to skill repo."
  exit 0
fi

git commit -m "feat(patterns): add $PATTERN_NAME"
git push origin HEAD:main
```

If this shell block exits non-zero at any step, stop the push flow and use the fallback response below.

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
