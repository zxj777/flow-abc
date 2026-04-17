# Harness 三层约束模型

> 本文档详细阐述 flow-abc 的核心理论模型：如何通过三层 Harness 约束 AI 的行为、产出和流程。

## 什么是 Harness

Harness 的字面意思是"马具/束具"——给马戴上缰绳，不是限制它跑，而是让它跑在正确的方向上。

在 AI 辅助开发的语境下，Harness 是一套**约束体系**，确保：
- AI 的行为可预测（不会每次给出风格迥异的代码）
- AI 的产出有质量保证（能通过自动化验证）
- AI 参与的边界清晰（哪些事 AI 做，哪些事人做）

## 三层模型

```
┌───────────────────────────────────────────────────┐
│                                                   │
│  Layer 3: Workflow Harness                        │
│  流程约束 — AI 在什么时候做什么事                    │
│                                                   │
│  ┌───────────────────────────────────────────┐    │
│  │                                           │    │
│  │  Layer 2: Eval Harness                    │    │
│  │  质量约束 — AI 的产出如何验证               │    │
│  │                                           │    │
│  │  ┌───────────────────────────────────┐    │    │
│  │  │                                   │    │    │
│  │  │  Layer 1: Prompt Harness          │    │    │
│  │  │  行为约束 — AI 怎么行动             │    │    │
│  │  │                                   │    │    │
│  │  └───────────────────────────────────┘    │    │
│  │                                           │    │
│  └───────────────────────────────────────────┘    │
│                                                   │
└───────────────────────────────────────────────────┘
```

越内层的约束越具体、越常被触发；越外层的约束越宏观、越少变动。

---

## Layer 1: Prompt Harness（行为约束）

### 定义

通过规则文件和上下文信息，约束 AI 在生成代码时的行为。这是最内层、最高频触发的约束——每次 AI 响应都会受到影响。

### 组成

```
Prompt Harness
├── 规则文件（Rules）     — 告诉 AI "怎么做"
├── 上下文文档（Context）  — 告诉 AI "环境是什么"
└── 外部 Skills          — 社区最佳实践的动态注入
```

### 规则文件

**载体**：`.ai/rules/*.md` → 编译为 `copilot-instructions.md`

**分类**：

| 文件 | 约束内容 | 示例 |
|------|---------|------|
| `coding.md` | 命名、风格、import 规范 | "组件用 PascalCase" |
| `architecture.md` | API 调用、状态管理、目录结构 | "使用封装的 request 方法" |
| `component.md` | 组件拆分、复用规则 | "优先使用已有组件" |
| `testing.md` | 测试规范、覆盖要求 | "每个页面至少有行为测试骨架" |

**规则编写原则**：

1. **声明式 + 示例**：先说规则，再给正/反例
   ```markdown
   ## 规则：API 调用必须使用封装的 request
   
   ✅ 正确
   import { request } from '@/utils/request';
   const data = await request.get('/api/users');
   
   ❌ 错误
   const data = await fetch('/api/users');
   const data = await axios.get('/api/users');
   ```

2. **具体且可执行**：避免模糊描述
   ```markdown
   ❌ "代码要写得好"
   ✅ "组件 Props 超过 3 个时，使用 interface 定义类型并导出"
   ```

3. **优先级标注**：关键规则标为 MUST，建议性规则标为 SHOULD
   ```markdown
   - **MUST**: 所有 API 调用必须有错误处理
   - **SHOULD**: 优先使用 const 声明变量
   ```

### 上下文文档

**载体**：`.ai/context/*.md`，按需加载（不编译进 copilot-instructions.md）

**作用**：给 AI 提供项目特定的背景信息，让它不需要"猜"。

| 文件 | 内容 | 加载时机 |
|------|------|---------|
| `project.md` | 项目概述、技术栈、架构图 | 新功能开发流程的 Step 1 |
| `components.md` | 组件索引（名称、Props、示例） | 设计转代码、编码开发 |
| `api.md` | API 接口清单 | 编码开发、生成 adapter |
| `glossary.md` | 业务术语表 | 需求分析、编码开发 |

**为什么不全部编译进 copilot-instructions.md**：
- 上下文窗口有限，全塞进去会导致"规则稀释"——AI 无法有效关注所有信息
- 按需加载确保当前环节只看到相关上下文

### 外部 Skills

**来源**：Copilot 平台注册的社区 Skills
**示例**：`vercel-react-best-practices`、`vercel-composition-patterns`
**加载方式**：Copilot 自动注入，不需要项目配置
**优先级**：项目规则 > Skills（冲突时项目规则覆盖）

**flow-abc 的职责**：
- `flow-abc init` 时推荐安装相关 Skills
- 不负责管理 Skills 的内容（由社区维护）

### 配置示例

```yaml
# .ai/rules/coding.md 的核心内容会被编译进：

# .github/copilot-instructions.md
# ============================================

## 代码规范

### 命名
- 组件文件：PascalCase（UserProfile.tsx）
- 工具函数：camelCase（formatDate.ts）
- Hook：以 use 开头（useUserList）

### API 调用
- MUST: 使用 @/utils/request 封装
- MUST: 所有请求必须有错误处理
- MUST: 返回数据通过 adapter 转换

### 组件
- MUST: 优先使用 @/components 中的已有组件
- SHOULD: Props 超过 3 个时使用 interface 定义
- MUST: 不要自行实现已有组件的功能
```

---

## Layer 2: Eval Harness（质量约束）

### 定义

通过自动化工具和审查机制，验证 AI 产出的质量。这一层回答："AI 写出来的东西好不好？"

### 组成

```
Eval Harness
├── 静态检查（Static）    — Lint / Type Check / Format
├── 动态验证（Dynamic）   — 测试运行
└── 智能审查（Review）    — AI Code Review
```

### 静态检查

**已有工具**，不需要额外建设：

| 工具 | 检查内容 | 触发时机 |
|------|---------|---------|
| ESLint | 代码规范、潜在错误 | 保存时 / Pre-commit |
| TypeScript | 类型正确性 | 保存时 / 编译 |
| Prettier | 代码格式 | 保存时 / Pre-commit |

**与 Prompt Harness 的关系**：
- Prompt Harness 让 AI "尽量"写正确的代码
- Eval Harness 的静态检查是"兜底"——即使 AI 违反了规则，Lint 也能抓住

### 动态验证

**测试是 AI 产出的最重要验证手段**：

```
规格书 → 测试骨架（预期行为） → 代码 → 测试补全 → 运行测试
                                                      │
                                                ┌─────┴─────┐
                                                │ 通过 → OK  │
                                                │ 失败 → 修复 │
                                                └───────────┘
```

**测试的双重角色**：
1. **需求的代码化表达** — 测试骨架定义了"代码应该做什么"
2. **产出的自动验证** — 测试运行验证了"代码是否做到了"

**对 Copilot coding agent 的特殊价值**：
Agent 可以自己运行测试、看到失败原因、自动修复——形成闭环。这是 Eval Harness 和 Workflow Harness 的交汇点。

### 智能审查（AI Code Review）

**定义在 `.ai/rules/review.md` 中**，不编译到 `copilot-instructions.md`，而是由流程模板在 Review 步骤按需读取。这样确保 Review 规则只在代码审查时加载，不干扰日常编码。

**检查维度**：

```markdown
# .ai/rules/review.md — Code Review 规则

## Review 原则
- 只报告真正重要的问题，不报告格式和风格（Lint 已覆盖）
- 每个问题标注优先级（P0/P1/P2）
- 给出具体的修复建议

## 检查清单

### P0（必须修复）
- [ ] 逻辑错误：条件判断、边界值、空值处理
- [ ] 安全问题：XSS、敏感数据暴露、eval/innerHTML
- [ ] 数据丢失：未保存的状态、竞态条件

### P1（建议修复）
- [ ] 规范违反：违反 .ai/rules/ 中的 MUST 规则
- [ ] 组件重复：重新实现了已有组件的功能
- [ ] 错误处理：缺少错误处理或处理不完善

### P2（可选优化）
- [ ] 性能：不必要的重渲染、大列表未虚拟化
- [ ] 可维护性：过长的函数、过深的嵌套
```

**高信噪比的实现方式**：
- 明确列出"不审查"的内容（格式、风格、命名偏好）
- 优先级标注确保 Reviewer 聚焦重要问题
- 给出修复建议而非仅指出问题

---

## Layer 3: Workflow Harness（流程约束）

### 定义

定义 AI 在整个开发流程中的参与方式和边界。这一层回答："AI 什么时候做什么事？人什么时候介入？"

### 组成

```
Workflow Harness
├── 环节定义（Stages）      — 6 个环节的输入/输出/完成信号
├── 流程模板（Templates）   — 标准化的开发流程 Prompt
└── 决策边界（Boundaries）  — AI 能做 vs 人必须做
```

### 环节定义

每个环节有明确的**输入**、**输出**和**完成信号**：

| 环节 | 输入 | 输出 | 完成信号 |
|------|------|------|---------|
| 需求分析 | PRD / 需求文档 | 页面规格书 | 用户确认规格书 |
| 设计稿 | 规格书 | Figma 线框图 | 用户确认设计 |
| 设计转代码 | 规格书 + 设计稿 | 页面代码骨架 | 代码可运行 |
| 编码开发 | 规格书 + 骨架 | 完整业务代码 | Lint + Type 通过 |
| 测试 | 规格书 + 代码 | 测试代码 | 测试运行通过 |
| 代码审查 | PR diff | Review 意见 | 人工 Approve |

**完成信号的两类**：
- **自动验证**：Lint 通过、测试通过、代码可编译（机器判断）
- **人工确认**：规格书 Review、设计确认、PR Approve（人工判断）

### 流程模板

存储在 `.ai/templates/` 中，定义标准化的开发流程：

```markdown
# .ai/templates/new-feature.md
# 新功能开发流程

## 前置条件
- PRD / 需求文档链接已准备好
- 开发分支已创建

## 步骤

### Step 1: 需求分析
读取以下上下文文件：
- .ai/context/project.md（项目架构）
- .ai/context/components.md（组件索引）
- .ai/context/glossary.md（业务术语）

从 PRD / 需求文档生成页面规格书，包含：
- 页面结构
- 组件映射
- 交互逻辑
- 数据模型 + Adapter 设计

等待用户确认规格书。

### Step 2: 设计稿（可选）
询问用户是否需要生成 Figma 线框图。
如果需要：通过 Figma MCP 生成 → 用户修改 → 确认。
如果不需要：跳过。

### Step 3: 生成测试骨架
从规格书生成行为测试骨架（只有 describe/it，无断言）。
等待用户确认测试用例覆盖度。

### Step 4: 生成页面代码
基于规格书和组件索引生成页面代码。
优先复用已有组件。

### Step 5: 编码开发
辅助完成业务逻辑、状态管理、API 调用。
遵循 .ai/rules/ 中的所有规则。

### Step 6: 补全测试
基于真实代码填充测试断言。
运行测试确认通过。

### Step 7: 提交 Review
提交 PR，触发 AI Code Review。
```

```markdown
# .ai/templates/modify-feature.md
# 已有功能修改流程

## 步骤

### Step 1: 定位目标代码
从需求描述中提取关键词，搜索项目路由和页面组件。
列出候选页面让用户确认。

### Step 2: 分析现有代码
读取目标页面及相关文件。
理解当前代码的结构、数据流和依赖关系。

### Step 3: 生成变更规格
明确需要新增/修改/删除的功能点。
标注影响范围。

### Step 4: 增量修改
在已有代码基础上修改，不推倒重来。
保持风格一致性。

### Step 5: 补充/更新测试
新增功能加新测试，修改功能更新已有测试。

### Step 6: 提交 Review
```

### 决策边界

明确哪些事 AI 可以做、哪些事人必须做：

| 决策类型 | AI 能做 | 人必须做 |
|---------|--------|---------|
| **代码实现** | 生成代码、重构、补全 | 确认最终方案 |
| **组件选择** | 推荐匹配的已有组件 | 确认组件选择是否合理 |
| **架构决策** | 给出方案建议 | 选择最终方案 |
| **测试用例** | 生成骨架和实现 | 确认覆盖度 |
| **错误修复** | 提出修复建议 | 确认修复方案 |
| **业务逻辑** | 根据 PRD 实现 | 确认理解是否正确 |

**核心原则**：AI 执行，人决策。AI 可以给出建议，但关键决策点必须有人工确认。

---

## 三层协同

三层 Harness 不是孤立的，它们协同工作：

```
用户发起任务
    │
    ▼
Layer 3 (Workflow) → 确定当前是哪个环节 → 加载对应的流程模板
    │
    ▼
Layer 1 (Prompt)   → 注入规则和上下文 → AI 生成代码
    │
    ▼
Layer 2 (Eval)     → Lint + Test + AI Review → 验证产出质量
    │
    ▼
通过 → 进入下一环节
失败 → 反馈到 Layer 1，AI 修复后重新验证
```

**示例**：开发一个新页面

1. **Workflow Harness** 触发"新功能开发"流程模板
2. **Prompt Harness** 注入项目规则和组件索引
3. AI 生成页面代码
4. **Eval Harness** 运行 Lint — 发现一个 ESLint 错误
5. 反馈到 AI → AI 修复 → 重新 Lint → 通过
6. **Eval Harness** 运行测试 — 全部通过
7. **Eval Harness** AI Review — 发现一个 P1 问题（漏了错误处理）
8. AI 修复 → 重新 Review → 通过
9. **Workflow Harness** 标记环节完成，进入下一环节
