# 规则文件体系设计

> 本文档定义 `.ai/` 目录的结构规范、规则编写指南、以及编译为 `copilot-instructions.md` 的机制。

## 设计原则

1. **Single Source of Truth** — `.ai/` 目录是规则的唯一数据源，`copilot-instructions.md` 是编译产物
2. **分类清晰** — 上下文（context）、规则（rules）、模板（templates）各司其职
3. **自动 + 手动** — 能自动生成的不手写，但保留手动补充的能力
4. **规则来源优先级** — 项目手动 > 项目自动推断 > 社区最佳实践

---

## 目录结构

### 单项目仓库

```
.ai/
├── context/                  # 项目上下文（详细信息，按需加载）
│   ├── project.md            # 项目概述、技术栈、架构
│   ├── components.md         # 组件索引（自动扫描生成）
│   ├── api.md                # API 接口清单（自动扫描生成）
│   └── glossary.md           # 业务术语表（手动维护）
│
├── rules/                    # 行为规则（编译进 copilot-instructions.md）
│   ├── coding.md             # 编码规范（命名、风格、import）
│   ├── architecture.md       # 架构约束（API、状态管理、目录结构）
│   ├── component.md          # 组件规范（复用、拆分、Props 设计）
│   └── testing.md            # 测试规范（骨架、断言、覆盖率）
│
├── templates/                # 流程 Prompt 模板
│   ├── new-feature.md        # 新功能开发流程
│   ├── modify-feature.md     # 已有功能修改流程
│   ├── bugfix.md             # Bug 修复流程
│   └── refactor.md           # 重构流程
│
└── config.yaml               # flow-abc 配置文件

# 编译产物（由 flow-abc sync 生成，不应手动编辑）
.github/copilot-instructions.md
```

### Monorepo

对于包含多个子项目的 monorepo，使用 `.ai-<name>/` 存放子项目专属规则，利用 GitHub Copilot 原生的 path-specific instructions 实现按路径加载：

```
.ai/                              # 共享规则（所有子项目通用）
├── rules/
│   ├── coding.md                 # 通用编码规范
│   ├── architecture.md           # 通用架构约束
│   └── testing.md                # 通用测试规范
└── context/
    └── project.md                # Monorepo 全局概述

.ai-web/                          # apps/web 专属规则
├── rules/
│   ├── coding.md                 # React + TypeScript 规范
│   └── architecture.md           # Web 端架构约束
├── context/
│   └── components.md             # Web 端组件索引
└── applyTo                       # 内容: apps/web/**

.ai-admin/                        # apps/admin 专属规则
├── rules/
│   ├── coding.md                 # Vue + TypeScript 规范
│   └── architecture.md           # Admin 端架构约束
├── context/
│   └── components.md             # Admin 端组件索引
└── applyTo                       # 内容: apps/admin/**

# 编译产物
.github/
├── copilot-instructions.md               ← 编译自 .ai/rules/（共享规则）
└── instructions/
    ├── web.instructions.md               ← 编译自 .ai-web/rules/（applyTo: apps/web/**）
    └── admin.instructions.md             ← 编译自 .ai-admin/rules/（applyTo: apps/admin/**）
```

**工作机制**：编辑 `apps/web/src/App.tsx` 时，Copilot 同时加载：
1. `.github/copilot-instructions.md`（共享规则，始终生效）
2. `.github/instructions/web.instructions.md`（匹配 `apps/web/**`）

两份指令**合并生效**，path-specific 优先级高于 repository-wide。

**`applyTo` 文件**：每个 `.ai-<name>/` 目录下的 `applyTo` 文件包含一行 glob 模式，指定该子项目对应的文件路径。支持标准 glob 语法：
- `apps/web/**` — 匹配 apps/web 下所有文件
- `packages/ui/**,packages/utils/**` — 逗号分隔多个路径
- `**/*.vue` — 按文件类型匹配

---

## 各目录详解

### context/ — 项目上下文

**作用**：给 AI 提供项目的背景信息，让它理解"这是一个什么项目"。

**加载方式**：按需加载（通过流程模板的 Step 1 指引 AI 读取相关文件）。不编译进 `copilot-instructions.md`，避免上下文窗口被占满。

#### project.md

```markdown
# 项目概述

## 基本信息
- **项目名**: xxx 管理系统
- **技术栈**: React 18 + TypeScript + Vite + Ant Design
- **包管理器**: pnpm
- **Node 版本**: >= 18

## 架构
- 路由方案: React Router v6，文件式路由
- 状态管理: Zustand（全局）+ React Query（服务端状态）
- 样式方案: CSS Modules + Ant Design 主题定制
- API 层: 统一封装在 src/utils/request.ts

## 目录结构
src/
├── api/          # 接口定义（按模块分文件）
├── adapters/     # 后端数据 → 前端视图模型转换
├── components/   # 通用组件
├── hooks/        # 通用自定义 Hook
├── pages/        # 页面（按模块分目录）
├── stores/       # Zustand Store
└── utils/        # 工具函数
```

#### components.md（自动生成 + 手动补充）

由 `flow-abc scan` 自动扫描生成。手动补充的内容用 `<!-- manual -->` 标记，扫描更新时不会覆盖。

```markdown
# 组件索引

> 由 flow-abc scan 自动生成，最后更新：2024-xx-xx
> 标记 <!-- manual --> 的部分为手动补充，更新时不会被覆盖

## 通用组件

### Button
- **路径**: `@/components/Button`
- **Props**: `type`, `size`, `loading`, `disabled`, `onClick`
- **使用频次**: 127 处
<!-- manual -->
- **注意**: 表单提交按钮统一用 `type="primary"`，危险操作用 `type="danger"`
<!-- /manual -->

### DataTable
- **路径**: `@/components/DataTable`
- **Props**: `columns`, `dataSource`, `pagination`, `loading`, `onRow`
- **使用频次**: 34 处
<!-- manual -->
- **适用场景**: 需要分页、排序、筛选的列表页面。简单列表用原生 Table。
<!-- /manual -->
```

#### api.md（自动生成 + 手动补充）

```markdown
# API 接口清单

## 用户模块 (src/api/user.ts)
- `GET /api/users` → getUserList(params) → UserVO[]
- `GET /api/users/:id` → getUserDetail(id) → UserVO
- `POST /api/users` → createUser(data) → UserVO
- `PUT /api/users/:id` → updateUser(id, data) → UserVO

## 订单模块 (src/api/order.ts)
- `GET /api/orders` → getOrderList(params) → OrderVO[]
- ...
```

#### glossary.md（手动维护）

```markdown
# 业务术语表

| 术语 | 英文 | 说明 |
|------|------|------|
| 工单 | Ticket | 客户提交的服务请求 |
| 工单池 | Ticket Pool | 未分配的工单集合 |
| 派单 | Dispatch | 将工单分配给处理人 |
```

---

### rules/ — 行为规则

**作用**：约束 AI 生成代码时的行为。这是 Prompt Harness 的核心。

**加载方式**：编译合并进 `copilot-instructions.md`，每次 Copilot 对话自动加载。

#### 规则编写规范

每条规则遵循以下格式：

```markdown
## [分类]: [规则名称]

**级别**: MUST / SHOULD / MAY
**说明**: 一句话描述规则

✅ 正确示例
```code
// 正确的代码
```

❌ 错误示例
```code
// 错误的代码
```

**原因**: 为什么要这样做（可选，帮助 AI 理解意图）
```

**级别定义**：
- **MUST**：必须遵守，违反即为错误
- **SHOULD**：强烈建议，有合理理由时可例外
- **MAY**：可选，按场景判断

#### coding.md 示例

```markdown
# 编码规范

## 命名: 文件命名
**级别**: MUST
- 组件文件: PascalCase (`UserProfile.tsx`)
- Hook 文件: camelCase + use 前缀 (`useUserList.ts`)
- 工具函数: camelCase (`formatDate.ts`)
- 常量文件: camelCase (`constants.ts`)，导出常量用 UPPER_SNAKE_CASE

## 导入: import 顺序
**级别**: SHOULD
1. React/框架导入
2. 第三方库
3. 项目别名导入 (@/)
4. 相对路径导入
5. 样式文件

## 类型: TypeScript 使用
**级别**: MUST
- 组件 Props 使用 `interface` 定义并导出
- 禁止使用 `any`，确实需要时使用 `unknown`
- 接口返回值必须有类型定义
```

#### architecture.md 示例

```markdown
# 架构约束

## API: 请求方式
**级别**: MUST
- 使用 `@/utils/request` 发送请求
- 禁止直接使用 fetch/axios
- 接口函数定义在 `src/api/[module].ts`

## API: 错误处理
**级别**: MUST
- 所有 API 调用必须有错误处理
- 使用 `message.error()` 提示错误

✅ 正确
```typescript
try {
  const data = await getOrderList(params);
  setOrders(adaptOrders(data));
} catch (error) {
  message.error('获取订单列表失败');
}
```

## API: 数据转换
**级别**: MUST
- 后端返回数据必须通过 adapter 转换为前端视图模型
- Adapter 文件放在 `src/adapters/[module].adapter.ts`

## 状态: 状态管理边界
**级别**: SHOULD
- 页面内部状态: useState
- 跨组件共享: Zustand Store
- 服务端数据: React Query
```

---

### templates/ — 流程模板

**作用**：定义标准化的开发流程，让 AI 在正确的时机做正确的事。

**使用方式**：用户启动流程时，AI 按模板步骤执行。

详细的模板内容参见 [02-harness-model.md](./02-harness-model.md) 的 Workflow Harness 部分。

---

### config.yaml — 配置文件

```yaml
# .ai/config.yaml — flow-abc 配置

# 项目基本信息（自动检测，可手动覆盖）
project:
  framework: react          # react | vue
  language: typescript
  packageManager: pnpm
  componentDir: src/components
  pageDir: src/pages
  apiDir: src/api
  adapterDir: src/adapters

# 规则配置
rules:
  # 基座规则（内置）
  base: universal
  # 扩展规则（内置 preset）
  presets:
    - react
    - antd
  # 编译目标
  compile:
    copilotInstructions: true    # 生成 .github/copilot-instructions.md

# 扫描配置
scan:
  components:
    dirs:
      - src/components
      - src/pages/**/components
    ignore:
      - "**/*.test.*"
      - "**/*.stories.*"
  api:
    dirs:
      - src/api

# 推荐的 Copilot Skills
recommendedSkills:
  - vercel-react-best-practices
  - vercel-composition-patterns
```

---

## 编译机制

### flow-abc sync

将 `.ai/rules/*.md` 编译合并为 `copilot-instructions.md`：

```
.ai/rules/coding.md          ─┐
.ai/rules/architecture.md     ├──▶  .github/copilot-instructions.md
.ai/rules/component.md        │
.ai/rules/testing.md          ─┘

.ai/rules/review.md              ──▶  不编译，由流程模板在 Review 步骤按需读取
```

**Monorepo 额外编译**：

```
.ai-web/rules/coding.md      ─┐
.ai-web/rules/architecture.md ┘──▶  .github/instructions/web.instructions.md
                                     (applyTo: apps/web/**)

.ai-admin/rules/coding.md    ─┐
.ai-admin/rules/architecture.md┘──▶  .github/instructions/admin.instructions.md
                                      (applyTo: apps/admin/**)
```

**编译规则**：
1. 按文件顺序拼接 rules 内容（review.md 除外）
2. 加上 header（说明这是自动生成的，不要手动编辑）
3. Review 规则不编译，由流程模板在 Review 步骤按需读取 `.ai/rules/review.md`
4. Monorepo 子项目规则编译为 `.github/instructions/<name>.instructions.md`，头部包含 `applyTo` frontmatter
5. 编译产物头部加注释：

```markdown
<!-- 
  此文件由 flow-abc sync 自动生成
  请勿手动编辑，修改请编辑 .ai/rules/ 下的源文件
  最后编译时间: 2024-xx-xx xx:xx
-->
```

### 何时需要 sync

- `flow-abc init` 后自动执行一次
- 修改了 `.ai/rules/` 或 `.ai-<name>/rules/` 下的文件后，手动运行 `flow-abc sync`
- 可以配置 Git hooks（pre-commit）自动 sync

---

## 规则来源与优先级

```
优先级从高到低：

1. 项目手动规则 (.ai/rules/*.md 中手动编写的部分)
   └── 团队讨论决定的特定约定

2. 项目自动推断 (flow-abc init/scan 生成)
   └── 从 ESLint/tsconfig/Prettier 配置推断
   └── 从代码样本分析推断

3. 内置 Preset (flow-abc 内置的规则模板)
   └── universal（通用基础）
   └── react / vue（框架特定）
   └── antd / element（组件库特定）

4. 外部 Skills (Copilot 平台动态注入)
   └── vercel-react-best-practices
   └── 等
```

**冲突解决**：上层覆盖下层。项目明确写了"用 Tailwind"，即使 Skill 建议用 CSS Modules，也以项目规则为准。

---

## 版本管理

`.ai/` 目录应该纳入 Git 版本管理：
- ✅ 提交 `.ai/` 目录和所有 `.ai-*/` 目录（规则是团队共识，应该共享）
- ✅ 提交编译产物（`copilot-instructions.md` 和 `.github/instructions/*.instructions.md`）
- `.gitignore` 无需排除 `.ai/` 或 `.ai-*/` 中的任何内容

编译产物虽然可以从源文件生成，但提交它们确保：
- 不依赖 flow-abc 工具也能使用 Copilot 规则
- PR Review 时可以看到规则变更的最终效果
