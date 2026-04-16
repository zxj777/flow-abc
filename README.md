# flow-abc

> AI 前端开发工作流 — Agent Skill

让 AI 在你的前端项目中按规矩写代码。flow-abc 是一个 [Agent Skill](https://agentskills.io)，为 Copilot CLI / Claude Code / Cursor 提供结构化的前端开发工作流。

## 安装

```bash
# 全局安装（推荐）
npx skills add user/flow-abc -g -y

# 项目级安装
npx skills add user/flow-abc
```

## 它做什么

安装后，AI 会自动获得以下能力：

- **初始化** — 分析你的项目，生成 `.ai/rules/` 编码规范 + `.ai/context/` 项目上下文
- **开发工作流** — 新功能 / 修改 / 修 bug 的结构化流程（需求 → 设计 → 编码 → 测试 → Review）
- **Code Review** — 基于项目规范的高信噪比 AI 审查
- **规则编译** — `.ai/rules/*.md` → `.github/copilot-instructions.md`

## 使用方式

直接用自然语言对话即可，Skill 会自动激活：

```
"初始化这个项目的 AI 规范"        → 分析项目 & 生成规则
"开发一个新功能：用户登录"         → 6 阶段开发工作流
"修改搜索功能，增加筛选"          → 定向修改工作流
"修复这个 bug"                   → Bug 修复工作流
"review 这段代码"                → AI Code Review
"重新扫描组件"                   → 刷新组件索引
```

## 核心理念：Three-Layer Harness

```
┌──────────────────────────────────────┐
│  Layer 3: Workflow Harness           │  ← 流程：6 阶段开发生命周期
│  ┌──────────────────────────────┐    │
│  │  Layer 2: Eval Harness       │    │  ← 质量：lint + test + AI review
│  │  ┌──────────────────────┐    │    │
│  │  │  Layer 1: Prompt      │    │    │  ← 行为：rules + context files
│  │  │  Harness              │    │    │
│  │  └──────────────────────┘    │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

- **Prompt Harness** — 规则文件约束 AI 每次对话的行为
- **Eval Harness** — 现有工具（lint/test/type-check）验证 AI 产出
- **Workflow Harness** — 分步工作流确保开发过程一致

## 初始化后的项目结构

```
.ai/                              # AI 配置目录（你编辑这里）
├── rules/                        # 行为规则
│   ├── coding.md                 # 编码规范
│   ├── architecture.md           # 架构约束
│   ├── testing.md                # 测试规范
│   └── review.md                 # Review 规则（不编译到 instructions）
└── context/                      # 项目上下文（按需加载）
    ├── project.md                # 项目概述 & 技术栈
    └── components.md             # 组件索引

.github/copilot-instructions.md  ← 从 .ai/rules/ 编译（AI 每次自动加载）
```

## Skill 目录结构

```
flow-abc/
├── SKILL.md              # Skill 入口（意图路由）
├── references/           # AI 参考文档
│   ├── init-guide.md     # 初始化指南
│   ├── workflow-new.md   # 新功能工作流
│   ├── workflow-modify.md# 修改工作流
│   ├── workflow-bugfix.md# Bug 修复工作流
│   ├── review-guide.md   # Review 规则
│   └── rule-examples/    # 规则格式示例
├── scripts/
│   └── sync.sh           # .ai/rules/ → copilot-instructions.md 编译脚本
└── docs/                 # 方法论文档（给人看）
```

## 方法论文档

- [全流程指南](docs/01-full-workflow.md) — 6 个环节的详细说明
- [Harness 三层模型](docs/02-harness-model.md) — 约束体系理论
- [规则文件体系](docs/03-rule-system.md) — `.ai/` 目录规范
- [最佳实践](docs/04-best-practices.md) — Do's & Don'ts

## License

MIT
