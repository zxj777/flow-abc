# 最佳实践与反模式

> 各环节的 Do's & Don'ts，以及实际使用中的常见坑和解决方案。

---

## 全局最佳实践

### ✅ Do: 给 AI 明确的边界

AI 在有明确约束时表现最好。模糊的指令会导致 AI "自由发挥"，产出不可预测。

```markdown
# ❌ 模糊
请帮我写一个用户列表页面

# ✅ 明确
请根据以下规格书写用户列表页面：
- 使用 @/components/DataTable 组件
- 数据通过 src/api/user.ts 的 getUserList 获取
- 使用 src/adapters/user.adapter.ts 转换数据
- 错误处理使用 message.error
- 参考 src/pages/order/list 的实现模式
```

### ✅ Do: 让 AI 先分析再动手

尤其是修改已有代码时，先让 AI 理解现有代码的结构和意图。

```markdown
# ❌ 直接改
在 OrderList 页面加一个导出功能

# ✅ 先分析
先分析 src/pages/order/list/index.tsx 的代码结构，
然后告诉我你打算在什么位置加导出功能、怎么加，
我确认后你再动手。
```

### ✅ Do: 利用已有代码作为参考

项目中已有的类似实现是最好的"示例"。

```markdown
# ✅ 指向已有实现
参考 src/pages/user/list 的实现方式，
为订单模块创建一个类似的列表页面。
```

### ❌ Don't: 一次让 AI 做太多

大任务拆成小步骤，每步确认后再继续。

```markdown
# ❌ 一次性
帮我完成整个订单模块，包括列表页、详情页、编辑页、所有接口和测试

# ✅ 分步
第一步：先做订单列表页的页面结构和数据加载
（确认 OK 后）
第二步：加上筛选和排序功能
（确认 OK 后）
第三步：写测试
```

### ❌ Don't: 跳过人工检查点

每个环节的人工检查点不是形式——AI 可能误解需求，早发现早修正。

---

## 环节 1：需求分析

### ✅ Do: 提供完整的 PRD 上下文

不要只给 PRD 的一部分。AI 需要完整上下文才能准确理解需求。

### ✅ Do: 明确标注 PRD 中的模糊点

如果 PRD 本身有含糊的地方，告诉 AI "这个点不确定，先按 X 方案做"。

### ❌ Don't: 跳过规格书直接写代码

规格书是需求的结构化表达，也是后续所有环节的基础。跳过它 = 失去一个重要的校验点。

### ❌ Don't: 让 AI 做业务决策

```markdown
# ❌ AI 不应该做的决策
"这个功能应该对所有用户开放还是只对管理员开放？"
→ 这是业务决策，必须人来确认

# ✅ AI 可以做的
"根据 PRD 描述，这个功能应该只对管理员角色开放，我来实现权限判断"
→ 从 PRD 中提取信息并实现，这是 AI 的工作
```

---

## 环节 2：设计稿

### ✅ Do: 把设计稿当作布局确认工具

线框图的目的是确认"东西放在哪"，不是确认"长什么样"。

### ✅ Do: 用截图确认代替打开 Figma

利用"说 → 改 → 看"的循环，在终端内完成设计确认。

### ❌ Don't: 在线框图上纠结细节

颜色、圆角、阴影——这些交给代码环节，组件库已经处理好了。

### ❌ Don't: 每个需求都走设计稿

小改动（加个按钮、改个文案）不需要设计稿。规格书 + 代码就够了。

---

## 环节 3：设计转代码

### ✅ Do: 先确认组件索引是最新的

```bash
npx flow-abc scan  # 更新组件索引
```

过时的组件索引会导致 AI 不知道新组件的存在，从而自己实现一个。

### ✅ Do: 组件匹配不上时先讨论

```markdown
# ✅ 好的处理方式
AI: 筛选面板没有找到匹配的已有组件。
    有两种方案：
    1. 新建 FilterPanel 组件
    2. 用 Ant Design 的 Form + Row/Col 组合
    
    你倾向哪种？
```

### ❌ Don't: 让 AI 悄悄创建新组件

规则应明确：创建新组件前必须告知用户。

```markdown
# .ai/rules/component.md
## 组件创建: 新组件审批
**级别**: MUST
- 需要创建新组件时，先说明原因和方案，等用户确认后再创建
- 禁止在不告知用户的情况下创建新组件
```

### ❌ Don't: 用内联样式代替组件

```tsx
// ❌ 项目有 Button 组件却用内联样式
<div style={{ padding: '8px 16px', background: '#1890ff', color: '#fff', cursor: 'pointer' }}
  onClick={handleClick}>提交</div>

// ✅ 使用已有组件
<Button type="primary" onClick={handleClick}>提交</Button>
```

---

## 环节 4：编码开发

### ✅ Do: 遵循项目已有的封装

这是最常见的问题——AI 倾向于用"最通用"的方式写代码，而忽略项目已有的封装。

```typescript
// ❌ AI 可能写出的代码
const response = await fetch('/api/users', {
  headers: { 'Authorization': `Bearer ${token}` }
});
const data = await response.json();

// ✅ 应该使用项目封装
import { request } from '@/utils/request';
const data = await request.get('/api/users');
// request 已经处理了 token 注入、拦截器、基础 URL 等
```

### ✅ Do: Adapter 层解耦前后端

```typescript
// ✅ 好 — adapter 层隔离
// src/adapters/order.adapter.ts
export function adaptOrder(raw: ApiOrderDTO): OrderVO {
  return {
    id: raw.id,
    customerName: raw.customer_info.name,
    totalAmount: formatCurrency(raw.total_amount_cents / 100),
    status: mapOrderStatus(raw.status_code),
  };
}

// 页面组件中
const orders = rawData.map(adaptOrder);

// ❌ 差 — 直接在组件里转换
const orders = rawData.map(item => ({
  id: item.id,
  customerName: item.customer_info.name,  // 后端字段散落在各处
  totalAmount: `¥${(item.total_amount_cents / 100).toFixed(2)}`,
}));
```

### ✅ Do: 增量修改保持风格一致

AI 新增的代码应该与已有代码"看不出区别"。

### ❌ Don't: 引入已有项目未使用的库

```markdown
# .ai/rules/coding.md
## 依赖: 新依赖引入
**级别**: MUST
- 不要引入项目中未安装的第三方库
- 如果确实需要新库，先告知用户并说明理由
```

### ❌ Don't: "顺便修复"无关问题

```markdown
# 规则
- 发现已有代码的问题，先提出建议，不要默默修改
- 保持改动范围聚焦在当前任务
```

---

## 环节 5：测试

### ✅ Do: 测试骨架要覆盖核心行为

不要面面俱到，聚焦在：
- 正常流程（Happy Path）
- 错误处理
- 关键交互

### ✅ Do: 测试描述用业务语言

```typescript
// ❌ 技术描述
it('should call API and set state');

// ✅ 业务描述
it('页面加载时应该显示订单列表');
it('网络错误时应该提示"加载失败"');
```

### ❌ Don't: 测试实现细节

```typescript
// ❌ 测试实现细节（脆弱）
it('should call useState with initial value []', () => {
  // 测试内部 state 的初始值——重构就挂
});

// ✅ 测试行为
it('初始状态应该显示空列表', () => {
  render(<OrderList />);
  expect(screen.getByText('暂无数据')).toBeInTheDocument();
});
```

### ❌ Don't: 生成无意义的测试

```typescript
// ❌ 为了覆盖率而写的无意义测试
it('should render without crashing', () => {
  render(<OrderList />);
  // 没有任何断言
});
```

---

## 环节 6：代码审查

### ✅ Do: AI Review 给出修复建议

不只是指出问题，还要说怎么改。

```markdown
# ✅ 好的 AI Review Comment
⚠️ **P1: 缺少错误处理**

`src/pages/order/list/index.tsx:45`

getOrderList() 没有 catch 错误。如果接口失败，页面会无响应。

建议修改：
```typescript
try {
  const data = await getOrderList(params);
  setOrders(adaptOrders(data));
} catch (error) {
  message.error('获取订单列表失败');
}
```
```

### ✅ Do: 人工 Review 聚焦高层问题

AI 已经检查了低层问题（Bug、规范、安全），人工 Reviewer 应该关注：
- 需求理解是否正确？
- 架构方案是否合理？
- 有没有更好的实现思路？

### ❌ Don't: AI Review 指出格式问题

格式交给 ESLint/Prettier，AI Review 应该聚焦逻辑层面。

### ❌ Don't: 忽略 AI Review 的 P0 问题

P0 问题（逻辑错误、安全漏洞）必须处理后才能合并。

---

## 常见坑与解决方案

| 坑 | 表现 | 解决方案 |
|---|---|---|
| 规则太多，AI "稀释" | copilot-instructions.md 很长，AI 无法全部遵守 | 精简规则，只保留 MUST 级别；其余放 context 按需加载 |
| 组件索引过时 | AI 不知道新组件，重复实现 | 配置 Git hooks 自动扫描；定期 `flow-abc scan` |
| AI 理解错需求 | 写出来的代码方向错误 | 规格书环节必须人工确认后再继续 |
| 测试骨架太细 | 前置阶段就写了大量测试描述 | 骨架只覆盖核心行为（5-10 个 it），不要穷举 |
| AI Review 误报 | 报了很多不是问题的问题 | 优化 `.ai/rules/review.md` 规则，加入"不要报告"的明确列表 |
| 不同 AI 对话间不一致 | 每次新对话 AI 又忘了规则 | 核心规则必须在 copilot-instructions.md 里（自动加载） |
