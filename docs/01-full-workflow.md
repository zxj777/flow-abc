# flow-abc 全流程指南：AI 驱动前端开发

> 本文档定义了 AI 在前端开发全流程中的角色、操作方式和约束机制。

## 目录

- [流程总览](#流程总览)
- [环节 1：需求分析](#环节-1需求分析)
- [环节 2：设计稿（可选）](#环节-2设计稿可选)
- [环节 3：设计转代码](#环节-3设计转代码)
- [环节 4：编码开发](#环节-4编码开发)
- [环节 5：测试](#环节-5测试)
- [环节 6：代码审查](#环节-6代码审查)

---

## 流程总览

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  需求分析  │───▶│ 设计稿    │───▶│ 设计转代码 │───▶│ 编码开发  │───▶│  测试     │───▶│ 代码审查  │
│          │    │ (可选)    │    │          │    │          │    │          │    │          │
│ 飞书CLI   │    │ Figma MCP │    │ 组件匹配  │    │ 规则约束  │    │ 混合TDD  │    │ AI+人工  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
      │                                                                               │
      │              PRD 有截图时可跳过设计稿                                            │
      └─────────────────────────────────────────────────────────────────────────────────┘
                                    反馈循环
```

### 核心原则

1. **AI 是协作者，不是替代者** — 每个环节都有人工检查点
2. **Harness（约束）贯穿全程** — AI 的行为受规则文件、质量检查、流程定义三层约束
3. **渐进式采纳** — 可以只用部分环节，不必全流程一步到位
4. **项目规则优先** — 项目特定约定覆盖通用最佳实践

### 两条开发路径

| | 路径 A：新页面/大功能 | 路径 B：已有页面改动 |
|---|---|---|
| **适用场景** | 新模块、新页面、大型功能 | 在已有页面上增加/修改功能 |
| **流程** | 全部 6 个环节 | 跳过设计稿，可能跳过设计转代码 |
| **AI 起点** | 从 PRD 开始 | 从定位已有代码开始 |

---

## 环节 1：需求分析

### 目标

从 PRD 文档中提取结构化的技术需求，生成「页面/功能规格书」作为后续环节的输入。

### 输入 / 输出

| | 内容 |
|---|---|
| **输入** | 飞书 PRD 文档（通过飞书 CLI 获取） |
| **输出** | 页面/功能规格书（Markdown） |
| **人工检查点** | Review 规格书，确认理解正确 |

### 工具链

- **飞书 CLI**：拉取 PRD 文档内容
- **Copilot CLI**：解析 PRD，生成规格书

### 操作流程

#### Step 1：获取 PRD

通过飞书 CLI 获取 PRD 文档内容，提供给 Copilot CLI 作为上下文。

#### Step 2：AI 生成规格书

AI 解析 PRD，输出结构化的「页面/功能规格书」，包含以下部分：

**a) 页面结构**
```markdown
## 页面结构

### 顶部区域
- 面包屑导航
- 页面标题 + 操作按钮组

### 主体区域
- 左侧：筛选面板（折叠式）
- 右侧：数据表格
  - 表头：可排序
  - 行操作：编辑、删除、查看详情
  - 分页器

### 底部区域
- （无）
```

**b) 组件映射**

AI 会对照项目组件索引（`.ai/context/components.md`），将页面区块映射到已有组件：

```markdown
## 组件映射

| 页面区块 | 匹配的组件 | 来源 | 备注 |
|---------|-----------|------|------|
| 面包屑导航 | `<Breadcrumb>` | @/components/Breadcrumb | 已有组件 |
| 操作按钮组 | `<ButtonGroup>` | @/components/ButtonGroup | 已有组件 |
| 筛选面板 | — | — | 需新建 |
| 数据表格 | `<DataTable>` | @/components/DataTable | 已有组件 |
| 分页器 | `<Pagination>` | @/components/Pagination | 已有组件 |
```

**c) 交互逻辑**
```markdown
## 交互逻辑

1. 页面加载 → 调用 GET /api/items 获取列表数据
2. 点击筛选条件 → 重新请求带 filter 参数的列表
3. 点击排序表头 → 重新请求带 sort 参数的列表
4. 点击"编辑" → 打开编辑弹窗（Modal）
5. 提交编辑 → 调用 PUT /api/items/:id → 成功提示 + 刷新列表
```

**d) 数据模型 + Adapter 层**

```markdown
## 数据模型

### 前端视图模型（View Model）
```typescript
interface ItemVO {
  id: string;
  name: string;
  status: 'active' | 'inactive';
  createdAt: string; // 格式化后的日期字符串
  actions: ('edit' | 'delete' | 'view')[];
}
```

### Adapter（后端 → 前端转换）
```typescript
// src/adapters/item.adapter.ts
// 后端接口确定后，只需修改此文件
function adaptItem(raw: ApiItemDTO): ItemVO {
  return {
    id: raw.id,
    name: raw.item_name,           // 字段映射
    status: raw.is_active ? 'active' : 'inactive', // 逻辑转换
    createdAt: formatDate(raw.created_at),          // 格式化
    actions: getAvailableActions(raw.permissions),   // 权限计算
  };
}
```

> **为什么需要 Adapter 层**：前后端数据结构很可能不一致。Adapter 层将后端数据转换为前端视图模型，后端接口确定后只需修改 Adapter，不影响组件代码。
```

#### Step 3：定位已有页面（路径 B）

当需求是修改已有页面时，AI 需要定位到相关代码：

1. **自动匹配**：从 PRD 提取页面名称/路由关键词，搜索项目的路由配置文件
2. **候选确认**：列出匹配的页面组件，让用户确认
3. **上下文加载**：读取目标页面的代码和相关依赖

```
AI: 我从 PRD 中识别到要修改的是"订单列表"页面，
    在项目中找到以下匹配：
    
    1. src/pages/order/list/index.tsx  (路由: /order/list)
    2. src/pages/order/OrderList.tsx   (路由: /orders)
    
    请确认是哪个页面？
```

#### Step 4：人工 Review

用户 Review 规格书，确认：
- 页面结构是否正确理解了 PRD
- 组件映射是否合理
- 交互逻辑是否完整
- 数据模型是否合理

**修改方式**：直接告诉 AI 需要调整的部分，AI 更新规格书。

---

## 环节 2：设计稿（可选）

### 目标

生成轻量级 Figma 线框图，让团队快速确认页面布局和交互流程。

### 何时跳过

- PRD 已包含清晰的页面截图/原型
- 修改已有页面的小功能（路径 B）
- 团队确认不需要设计确认

> 跳过需要用户明确确认。

### 设计策略：轻量线框图

**不追求高保真**。原因：
- 项目已有组件库，UI 细节由代码保证
- 线框图的价值在于确认布局和信息架构
- 高保真设计的维护成本高，性价比低

### 工具链

- **Figma MCP**：生成和修改设计稿
- **截图回传**：每次修改后自动截图返回终端

### 操作流程

#### Step 1：AI 生成线框图

AI 根据规格书中的页面结构，通过 Figma MCP 生成线框图：
- 布局区块（Header、Sidebar、Main、Footer）
- 占位组件（标注组件名称和大致位置）
- 基本的间距和对齐

#### Step 2：用户修改（自然语言驱动）

用户通过自然语言描述修改需求：

```
用户: 把筛选面板从左侧移到顶部，改成水平排列
AI:   [通过 Figma MCP 修改布局]
      [自动截图回传]
      已修改，筛选面板现在是水平排列在表格上方。看看效果？
```

**交互循环**："说 → 改 → 看" — 用户不需要打开 Figma 即可完成设计确认。

#### Step 3：确认完成

用户确认设计稿 OK 后，进入下一环节。

---

## 环节 3：设计转代码

### 目标

将设计稿/规格书转化为页面代码，最大程度复用项目已有组件。

### 核心问题：组件复用

不复用组件的 AI 生成代码 = 技术债务。以下机制确保组件复用率：

### 三步法

#### Step 1：组件索引

项目维护一份组件清单（`.ai/context/components.md`），由 `flow-abc scan` 自动扫描生成 + 手动补充：

```markdown
# 组件索引

## 通用组件

### Button
- **路径**: `@/components/Button`
- **Props**: `type: 'primary' | 'default' | 'danger'`, `size: 'sm' | 'md' | 'lg'`, `loading: boolean`
- **使用示例**:
  ```tsx
  <Button type="primary" onClick={handleSubmit}>提交</Button>
  ```

### DataTable
- **路径**: `@/components/DataTable`
- **Props**: `columns: Column[]`, `dataSource: any[]`, `pagination: PaginationConfig`
- **使用示例**:
  ```tsx
  <DataTable columns={columns} dataSource={items} pagination={{ pageSize: 20 }} />
  ```
- **适用场景**: 需要展示列表数据且支持排序、筛选、分页的场景

## 业务组件

### OrderStatusTag
- **路径**: `@/components/business/OrderStatusTag`
- **Props**: `status: OrderStatus`
- **说明**: 根据订单状态显示不同颜色的标签
```

**自动扫描**机制：
- 扫描 `src/components/` 目录
- 解析组件文件的 Props 类型定义（TypeScript AST）
- 从项目代码中提取使用示例
- 生成 Markdown 格式的组件清单

**手动补充**：
- 自动扫描可能遗漏隐式约定（如"这个组件在哪些场景下不要用"）
- 业务组件的使用场景说明往往需要人工补充

#### Step 2：设计→组件映射

AI 分析设计稿/规格书中的每个 UI 区块，按以下优先级匹配：

1. **精确匹配**：区块的功能/名称与组件索引中的组件完全对应
2. **语义匹配**：按功能语义（"表格" → DataTable，"按钮" → Button）
3. **组合匹配**：多个已有组件组合使用
4. **创建新组件**：以上都不匹配时才创建新组件

#### Step 3：代码生成

```tsx
// ✅ 正确 — 复用已有组件
import { Button, DataTable, Pagination } from '@/components';
import { OrderStatusTag } from '@/components/business';

// ❌ 错误 — 不应自行实现已有组件的功能
const MyButton = styled.button`...`; // 项目已有 Button 组件
```

---

## 环节 4：编码开发

### 目标

在规则约束下，AI 辅助完成业务代码编写。这是 AI 参与最多、约束最重要的环节。

### 四维 Harness

#### 维度 1：代码规范约束

**规则来源（优先级从高到低）**：
1. **项目手动约定** — 团队特有规范，优先级最高
2. **项目自动推断** — 从 ESLint、Prettier、tsconfig、代码样本中推断
3. **社区最佳实践** — Copilot Skills（如 `vercel-react-best-practices`）

**规则格式：声明式 + 少量示例**

```markdown
## 命名规范
- 组件文件：PascalCase（`UserProfile.tsx`）
- 工具函数：camelCase（`formatDate.ts`）
- 常量：UPPER_SNAKE_CASE（`MAX_RETRY_COUNT`）
- 自定义 Hook：以 `use` 开头（`useUserList`）

## 示例
```tsx
// ✅ 好
export function UserProfile({ userId }: Props) { ... }
export function useUserList() { ... }

// ❌ 不好
export function userProfile({ userId }: Props) { ... }  // 组件不是 PascalCase
export function getUserList() { ... }                    // Hook 没有 use 前缀
```
```

**存储与加载**：
- 规则源文件：`.ai/rules/coding.md`
- 编译产物：`copilot-instructions.md`（Copilot 自动加载）
- Skills 补充：由 Copilot 平台自动注入，项目规则优先级更高

#### 维度 2：架构约束

告诉 AI "项目的代码怎么组织、数据怎么流动"：

**a) API 调用规范**
```markdown
## API 调用
- 使用项目封装的 `request` 方法（`@/utils/request`）
- 禁止直接使用 `fetch` 或 `axios`
- 接口定义放在 `src/api/` 目录
- 返回数据通过 adapter 转换为视图模型

## 错误处理
- 使用 `message.error()` 显示错误提示
- 所有 API 调用必须有错误处理（try-catch 或 .catch）
```

**b) 状态管理**
```markdown
## 状态管理
- 页面级状态：使用组件内 state
- 跨组件共享状态：使用 [具体方案]
- 服务端数据缓存：使用 [React Query / SWR / 无]
```

**c) 目录结构**
```markdown
## 目录结构
src/
├── api/          # 接口定义
├── adapters/     # 数据转换层
├── components/   # 通用组件
├── hooks/        # 自定义 Hook
├── pages/        # 页面组件
│   └── [module]/
│       ├── index.tsx        # 页面入口
│       ├── components/      # 页面私有组件
│       └── hooks/           # 页面私有 Hook
├── stores/       # 全局状态
└── utils/        # 工具函数
```

**识别与初始化**：
- `flow-abc init` 自动扫描项目，识别已有架构模式
- 已有封装（如 API 层）→ 写入规则，AI 遵循
- 简陋部分（如错误处理）→ 给出改进建议，用户决定采纳与否
- 日常开发不再提出改进建议（只在 `flow-abc audit` 时重新评估）

#### 维度 3：上下文注入

**自动注入（核心规则）**：
- 编译进 `copilot-instructions.md`，每次对话自动加载
- 包含：代码规范、架构约束、命名规则

**按需加载（详细上下文）**：
- 开发流程（Prompt 模板）的第一步就是加载相关上下文
- 比如"开发新功能"流程会先读取组件索引和 API 清单

**上下文文档清单**：
| 文件 | 内容 | 维护方式 |
|------|------|---------|
| `.ai/context/project.md` | 项目概述、技术栈、架构 | 手动 |
| `.ai/context/components.md` | 组件索引 | 自动扫描 + 手动补充 |
| `.ai/context/api.md` | API 接口清单 | 自动扫描 + 手动补充 |
| `.ai/context/glossary.md` | 业务术语表 | 手动 |

#### 维度 4：增量开发

AI 在已有代码上开发时，必须遵循"先读懂，再动手"原则：

```markdown
## 增量开发规则
- 修改已有文件前，先分析当前代码的结构和意图
- 优先修改已有逻辑，不要创建重复的函数/组件
- 新增代码必须与已有代码风格保持一致
- 如果发现已有代码有问题，先提出建议，不要默默"修复"
```

---

## 环节 5：测试

### 目标

通过测试验证 AI 产出代码的正确性，同时以测试骨架作为需求的代码化表达。

### 策略：混合模式（前置骨架 + 后置补全）

#### Step 1：前置 — 生成行为测试骨架

在编码开发**之前**，AI 从规格书生成测试骨架：

```typescript
// src/pages/order/list/__tests__/OrderList.test.tsx

describe('OrderList 页面', () => {
  describe('数据加载', () => {
    it('页面加载时应该请求订单列表接口');
    it('加载中应该显示 loading 状态');
    it('加载失败应该显示错误提示');
    it('列表为空时应该显示空状态');
  });

  describe('筛选功能', () => {
    it('选择筛选条件后应该重新请求列表');
    it('清除筛选应该恢复默认列表');
  });

  describe('排序功能', () => {
    it('点击表头应该按该列排序');
    it('再次点击应该切换排序方向');
  });

  describe('行操作', () => {
    it('点击编辑应该打开编辑弹窗');
    it('编辑提交成功应该刷新列表');
    it('点击删除应该弹出确认框');
  });
});
```

**特点**：
- 只有 `describe` 和 `it` 描述，没有具体实现
- 是需求的代码化表达——每个 `it` 对应一个行为预期
- 人可以 Review：确认测试用例是否覆盖了需求

#### Step 2：编码开发

开发者和 AI 参考测试骨架进行编码。测试骨架是参考而非强制约束——不要求 TDD 式的"先跑通测试再写代码"。

#### Step 3：后置 — AI 补全测试实现

代码编写完成后，AI 基于**真实代码**填充测试断言：

```typescript
describe('数据加载', () => {
  it('页面加载时应该请求订单列表接口', async () => {
    const mockData = [{ id: '1', name: '订单A' }];
    vi.mocked(getOrderList).mockResolvedValue(mockData);

    render(<OrderList />);

    await waitFor(() => {
      expect(getOrderList).toHaveBeenCalledWith({ page: 1, pageSize: 20 });
    });
  });

  it('加载失败应该显示错误提示', async () => {
    vi.mocked(getOrderList).mockRejectedValue(new Error('网络错误'));

    render(<OrderList />);

    await waitFor(() => {
      expect(screen.getByText('加载失败')).toBeInTheDocument();
    });
  });
});
```

#### Step 4：运行验证

```bash
npm test -- --run src/pages/order/list
```

测试通过 = 代码行为符合预期。

---

## 环节 6：代码审查（Code Review）

### 目标

AI 作为前置过滤器拦截常见问题，人工 Reviewer 聚焦高价值判断。

### 模式：AI 先审 + 人工终审

#### AI Review

AI Review 规则定义在 `.ai/rules/review.md` 中，有两种自动加载方式：
- **Copilot CLI**：流程模板（`.ai/templates/`）在 Review 步骤自动指令读取该文件
- **Copilot Coding Agent**：通过编译生成的 `AGENTS.md` 自动加载

**检查维度（按优先级）**：

| 优先级 | 维度 | 关注点 |
|-------|------|-------|
| P0 | 逻辑正确性 | 潜在 Bug、边界情况遗漏、空值处理 |
| P0 | 安全性 | XSS、敏感数据暴露、不安全的 eval/innerHTML |
| P1 | 规范一致性 | 是否符合 `.ai/rules/` 中定义的约定 |
| P1 | 组件复用 | 是否重复实现了已有组件的功能 |
| P2 | 性能 | 不必要的重渲染、大数据量处理、内存泄漏 |

**高信噪比原则**：
- ✅ 报告：真正的 Bug、安全漏洞、架构违反
- ❌ 不报告：格式问题（交给 Lint）、风格偏好、微小的命名建议

**输出**：PR Comment，标注优先级和建议修改方式。

#### 人工 Review

人工 Reviewer 的关注点：
- 业务逻辑是否正确理解
- 架构决策是否合理
- 设计取舍是否得当
- AI Review 标记的问题是否需要处理

---

## 附录：环节快速参考

| 环节 | 输入 | 产出 | 工具 | 人工检查点 | 可跳过？ |
|------|------|------|------|-----------|---------|
| 需求分析 | 飞书 PRD | 页面规格书 | 飞书 CLI + Copilot | Review 规格书 | 否 |
| 设计稿 | 规格书 | Figma 线框图 | Figma MCP | 确认设计 | 是 |
| 设计转代码 | 规格书/设计稿 | 页面代码 | Copilot + 组件索引 | Review 代码 | 否 |
| 编码开发 | 规格书 + 骨架 | 业务代码 | Copilot CLI | — | 否 |
| 测试 | 规格书 + 代码 | 测试代码 | Copilot CLI | Review 测试 | 否 |
| 代码审查 | PR diff | Review 意见 | Copilot Agent | 人工终审 | 否 |
