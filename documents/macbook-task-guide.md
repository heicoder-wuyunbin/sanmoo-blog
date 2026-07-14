# MacBook 任务执行指南

## 1. 文档定位

本文档为 MacBook AI 代理执行 M0-M5 任务的详细指南，基于以下上位文档：

- [plan.md](file:///c:/workspace/sanmoo-blog/documents/plan.md) — 业务架构优化计划
- [implementation-tasks.md](file:///c:/workspace/sanmoo-blog/documents/implementation-tasks.md) — 实施任务清单
- [compliance-api-contract.md](file:///c:/workspace/sanmoo-blog/documents/compliance-api-contract.md) — L4 合规接口契约
- [deployment-and-retention-summary.md](file:///c:/workspace/sanmoo-blog/documents/deployment-and-retention-summary.md) — L5 部署与数据保留策略

**执行设备**：MacBook

**允许修改**：`sanmoo-vite/**`、`sanmoo-mp/**`、`README.md`

**禁止修改**：`sanmoo-server-go/**`、`sanmoo_blog_schema.sql`、`docker-compose.yaml`、`DEPLOY.md`

---

## 2. 当前差距分析

### 2.1 后端接口契约 vs 前端实现

根据 [compliance-api-contract.md](file:///c:/workspace/sanmoo-blog/documents/compliance-api-contract.md)，后端已提供以下合规字段：

| 字段名 | 类型 | 后端接口 | 前端支持情况 |
|--------|------|----------|-------------|
| `privacyPolicy` | string | ✅ 已实现 | ✅ 已支持 |
| `filingInfo` | string (JSON) | ✅ 已实现 | ❌ 未支持 |
| `contactInfo` | string (JSON) | ✅ 已实现 | ❌ 未支持 |
| `dataRetentionPolicy` | string | ✅ 已实现 | ❌ 未支持 |
| `accountDeletionGuide` | string | ✅ 已实现 | ❌ 未支持 |

### 2.2 后端 API 端点

| API | 方法 | 说明 | 前端调用情况 |
|-----|------|------|-------------|
| `/web/compliance` | GET | Web 端合规信息 | ❌ 未调用 |
| `/mp/compliance` | GET | 小程序端合规信息 | ❌ 未调用 |
| `/mp/privacy-policy` | GET | 小程序隐私政策详情 | ✅ 已调用（部分） |
| `/admin/settings/privacy` | GET | 管理端获取合规配置 | ✅ 已调用（部分） |
| `/admin/settings/privacy` | PUT | 管理端更新合规配置 | ✅ 已调用（部分） |

### 2.3 当前前端问题清单

**Web 端问题：**
1. `PrivacyPolicy.tsx` 备案信息硬编码，未从 API 读取
2. `PrivacySettings.tsx` 仅支持 `privacyPolicy` 字段，缺少其他合规字段
3. `types.ts` 中 `PrivacyConfig` 类型定义不完整
4. 页脚组件缺少备案信息展示位

**小程序端问题：**
1. 隐私政策页面仅展示 `content`，缺少数据保留说明和账号注销说明
2. 关于页缺少备案信息展示
3. 个人中心缺少账号注销入口

---

## 3. M0-M5 任务详细执行指南

### M0. 前端信息架构与文案基线设计

#### 3.1.1 任务目标

统一 Web、后台、小程序的产品语义，收敛为"个人原创内容站 + 轻量阅读分发端"。

#### 3.1.2 执行步骤

1. **审查现有文案**：阅读以下文件，识别平台化表达
   - `sanmoo-vite/src/pages/web/Home.tsx`
   - `sanmoo-vite/src/pages/web/About.tsx`
   - `sanmoo-vite/src/pages/admin/Dashboard.tsx`
   - `sanmoo-mp/miniprogram/pages/about/index.ts`
   - `sanmoo-mp/miniprogram/pages/mine/index.ts`

2. **产出信息架构文档**：在 `documents/` 目录下创建 `frontend-architecture.md`，包含：
   - Web 端页面层级关系
   - 小程序端页面层级关系
   - 需要降平台化表达的文案清单
   - 需要弱化或隐藏的入口清单

3. **产出 README 改版提纲**：在 `documents/` 目录下创建 `readme-redesign-outline.md`

#### 3.1.3 验收标准

- 文案统一强调个人原创内容站定位
- 不出现平台化、社区化扩张方向
- 不修改任何后端、数据库、部署文件

---

### M1. Web 站点对外表达重构

#### 3.2.1 任务目标

重构 Web 前台的对外表达，使其更符合个人备案友好型内容站定位。

#### 3.2.2 执行步骤

1. **更新首页文案** — `sanmoo-vite/src/pages/web/Home.tsx`
   - 弱化平台化表达，强调个人原创
   - 添加备案信息展示位

2. **更新关于页** — `sanmoo-vite/src/pages/web/About.tsx`
   - 明确站点是个人原创内容站
   - 展示作者信息和联系方式

3. **更新页脚** — `sanmoo-vite/src/pages/web/components/WebFooter.tsx`
   - 添加备案信息展示（从 API 获取）
   - 添加联系方式展示（从 API 获取）
   - 添加隐私政策链接

4. **更新隐私政策页** — `sanmoo-vite/src/pages/web/PrivacyPolicy.tsx`
   - 从 `/web/compliance` API 获取备案信息、数据保留说明、账号注销说明
   - 动态渲染备案信息，不再硬编码

#### 3.2.3 API 调用示例

```typescript
// 添加新 API 调用
export async function fetchWebCompliance() {
  return request<{
    privacyPolicy: string;
    filingInfo: string;
    contactInfo: string;
    dataRetentionPolicy: string;
    accountDeletionGuide: string;
  }>('/web/compliance');
}
```

#### 3.2.4 `filingInfo` JSON 格式

```json
{
  "icpCode": "京ICP备xxxxxxxx号",
  "filingUrl": "https://beian.miit.gov.cn",
  "recordType": "个人"
}
```

#### 3.2.5 `contactInfo` JSON 格式

```json
{
  "email": "contact@example.com",
  "wechat": "example_wx",
  "github": "example"
}
```

---

### M2. 后台信息架构与菜单收敛

#### 3.3.1 任务目标

把后台前端从"平台后台视觉感知"调整为"站长后台"。

#### 3.3.2 执行步骤

1. **更新后台导航** — `sanmoo-vite/src/pages/Admin.tsx`
   - 强化内容管理入口（文章、分类、标签、专题）
   - 弱化低频平台型能力入口（用户管理、角色权限）

2. **更新设置页结构** — `sanmoo-vite/src/pages/admin/Settings.tsx`
   - 调整为"站点品牌 / 合规 / 渠道 / 基础设施"四类配置
   - 合并相关设置页

3. **更新隐私政策设置** — `sanmoo-vite/src/pages/admin/settings/PrivacySettings.tsx`
   - 添加 `filingInfo` 字段输入框（JSON 格式）
   - 添加 `contactInfo` 字段输入框（JSON 格式）
   - 添加 `dataRetentionPolicy` 字段输入框
   - 添加 `accountDeletionGuide` 字段输入框

4. **更新类型定义** — `sanmoo-vite/src/services/blog/types.ts`

```typescript
export type PrivacyConfig = {
  privacyPolicy: string;
  filingInfo: string;
  contactInfo: string;
  dataRetentionPolicy: string;
  accountDeletionGuide: string;
};
```

#### 3.3.3 验收标准

- 后台主导航突出内容管理
- 设置页结构更清晰
- 不破坏已有基础操作流程

---

### M3. 小程序轻阅读模式改造

#### 3.4.1 任务目标

把小程序体验收敛为轻量阅读分发端，保留阅读、收藏、历史、订阅，弱化重运营痕迹。

#### 3.4.2 执行步骤

1. **更新首页** — `sanmoo-mp/miniprogram/pages/index/index.ts`
   - 弱化推荐运营感知
   - 强化文章阅读入口

2. **更新隐私政策页** — `sanmoo-mp/miniprogram/pages/privacy/index.ts`
   - 调用 `/mp/privacy-policy` 获取完整内容
   - 展示数据保留说明和账号注销说明

3. **更新关于页** — `sanmoo-mp/miniprogram/pages/about/index.ts`
   - 添加备案信息展示
   - 添加联系方式展示

4. **更新个人中心** — `sanmoo-mp/miniprogram/pages/mine/index.ts`
   - 添加账号注销入口
   - 弱化画像、标签运营感知

5. **添加 API 调用** — `sanmoo-mp/miniprogram/api/mp.ts`

```typescript
export async function fetchCompliance() {
  return request<{
    privacyPolicy: string;
    filingInfo: string;
    contactInfo: string;
    dataRetentionPolicy: string;
    accountDeletionGuide: string;
  }>('/mp/compliance', 'GET')
}

export async function deleteUserAccount() {
  return request<void>('/mp/user', 'DELETE')
}
```

#### 3.4.3 验收标准

- 小程序主路径围绕阅读消费
- 无明显平台化运营 UI 痕迹
- 轻量推荐可以保留，但不可喧宾夺主

---

### M4. README 产品定位与使用说明重写

#### 3.5.1 任务目标

把 `README.md` 从"泛系统介绍"重写为"个人技术内容平台"的项目说明。

#### 3.5.2 执行步骤

1. **阅读现有 README.md**
2. **重写内容**，包含以下章节：
   - 项目定位（个人原创技术内容发布与知识整理平台）
   - 技术架构（Web + 小程序双端分发）
   - 功能特性（文章管理、分类标签、全文搜索、阅读统计）
   - 部署指南（本地开发、Docker 部署）
   - 合规说明（个人备案友好、数据保留策略）
   - 许可证

3. **弱化平台化后台叙述**，避免出现社区、交易、会员等误导性表述

#### 3.5.3 验收标准

- README 首屏即可看出项目定位
- 项目描述与 `plan.md` 一致
- 不出现社区、交易、会员等误导性表述

---

### M5. 前端契约对齐与收口

#### 3.6.1 任务目标

完成 Web 与小程序对新契约的适配收口。

#### 3.6.2 执行步骤

1. **验证 Web API 适配** — `sanmoo-vite/src/services/blog/settings-api.ts`
   - 确保所有合规字段 API 调用完整
   - 验证类型定义与后端一致

2. **验证小程序 API 适配** — `sanmoo-mp/miniprogram/api/mp.ts`
   - 确保合规信息 API 调用完整
   - 验证账号注销接口实现

3. **清理旧文案和旧入口**
   - 删除硬编码的备案信息
   - 清理平台化表述

4. **验证页面兼容性**
   - 首页、关于页、隐私政策页正常显示
   - 管理后台设置页正常工作
   - 小程序各页面正常显示

#### 3.6.3 验收标准

- 前后端契约一致
- 页面无失效字段和明显兼容问题
- 文案、入口、信息架构与目标定位统一

---

## 4. 执行顺序建议

```
M0 → M1 → M2 → M3 → M4 → M5
```

**理由**：
- M0 先定信息架构和文案基线
- M1 改造 Web 前台对外表达
- M2 改造后台管理界面
- M3 改造小程序端
- M4 更新 README 文档
- M5 最终契约对齐收口

---

## 5. 风险与注意事项

### 5.1 风险清单

| 风险 | 等级 | 说明 | 应对措施 |
|------|------|------|----------|
| 后端接口字段名变更 | 中 | 前端需要同步更新 | 严格按照 compliance-api-contract.md 定义 |
| JSON 格式解析失败 | 低 | filingInfo/contactInfo 为 JSON 字符串 | 前端做好容错处理，解析失败时隐藏对应内容 |
| 小程序审核问题 | 中 | 隐私政策页面需符合微信要求 | 确保隐私政策完整，包含数据保留和账号注销说明 |

### 5.2 注意事项

1. **不修改后端代码**：所有前端修改必须基于已有的后端接口契约
2. **做好兼容处理**：当 API 返回空字符串或解析失败时，页面不应崩溃
3. **保留用户体验**：修改过程中确保核心阅读功能不受影响
4. **单独提交**：每个任务单独提交，不混合多个任务

---

## 6. 交付物清单

| 任务 | 交付物 |
|------|----------|
| M0 | `documents/frontend-architecture.md`、`documents/readme-redesign-outline.md` |
| M1 | Web 前台页面改造（Home.tsx、About.tsx、WebFooter.tsx、PrivacyPolicy.tsx） |
| M2 | 后台菜单调整、设置页结构调整、PrivacySettings.tsx 扩展 |
| M3 | 小程序页面改造（首页、隐私页、关于页、个人中心） |
| M4 | 更新后的 `README.md` |
| M5 | Web API 适配验证、小程序 API 适配验证、最终收口 |

---

## 7. 文档版本

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-07-14 | 初始版本，基于 L4/L5 交付物创建 MacBook 任务执行指南 |