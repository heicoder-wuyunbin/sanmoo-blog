# 合规配置与个人备案友好接口契约（L4 交付物）

## 1. 文档定位

本文档为 `implementation-tasks.md` 中 L4 任务的核心交付物，面向：

- **后端维护者**：明确合规配置字段、接口契约与数据策略
- **前端（MacBook）开发者**：提供稳定的合规信息接口契约，指导 M5 阶段的页面适配
- **陛下审核**：验证合规配置能力是否符合个人备案边界与用户数据保护要求

上位约束：

- [plan.md](file:///c:/workspace/sanmoo-blog/documents/plan.md)
- [business-boundary.md](file:///c:/workspace/sanmoo-blog/documents/business-boundary.md)
- [config-domain-mapping.md](file:///c:/workspace/sanmoo-blog/documents/config-domain-mapping.md)

---

## 2. 合规配置字段定义

### 2.1 数据表结构

合规配置存储在 `t_blog_compliance_config` 表（L1 阶段创建）：

| 字段名 | 类型 | 说明 | 前端可见性 |
|--------|------|------|----------|
| `privacy_policy` | text | 隐私政策内容（支持 Markdown） | Web + 小程序 |
| `filing_info` | varchar(500) | 备案信息（JSON格式） | Web + 小程序 |
| `contact_info` | varchar(500) | 联系方式（JSON格式） | Web + 小程序 |
| `data_retention_policy` | text | 数据保留说明（支持 Markdown） | Web + 小程序 |
| `account_deletion_guide` | text | 账号注销说明（支持 Markdown） | Web + 小程序 |

### 2.2 JSON 字段结构

#### 2.2.1 `filing_info` 格式

```json
{
  "icpCode": "京ICP备xxxxxxxx号",
  "filingUrl": "https://beian.miit.gov.cn",
  "recordType": "个人"
}
```

| 字段 | 说明 | 必填 |
|------|------|------|
| `icpCode` | ICP 备案号 | 否 |
| `filingUrl` | 备案查询链接 | 否 |
| `recordType` | 备案类型（个人/企业） | 否 |

#### 2.2.2 `contact_info` 格式

```json
{
  "email": "contact@example.com",
  "wechat": "example_wx",
  "github": "example"
}
```

| 字段 | 说明 | 必填 |
|------|------|------|
| `email` | 联系邮箱 | 否 |
| `wechat` | 微信号 | 否 |
| `github` | GitHub 用户名 | 否 |

---

## 3. 后端接口契约

### 3.1 公开端接口（读者可见）

#### 3.1.1 Web 端合规信息

```
GET /web/compliance
```

**响应格式：**

```json
{
  "code": 0,
  "data": {
    "privacyPolicy": "隐私政策内容（HTML或Markdown）",
    "filingInfo": "{\"icpCode\":\"京ICP备xxxxxxxx号\",\"filingUrl\":\"https://beian.miit.gov.cn\",\"recordType\":\"个人\"}",
    "contactInfo": "{\"email\":\"contact@example.com\"}",
    "dataRetentionPolicy": "数据保留说明内容",
    "accountDeletionGuide": "账号注销说明内容"
  }
}
```

**字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `privacyPolicy` | string | 隐私政策内容（空字符串表示未配置） |
| `filingInfo` | string | 备案信息（JSON字符串，空字符串表示未配置） |
| `contactInfo` | string | 联系方式（JSON字符串，空字符串表示未配置） |
| `dataRetentionPolicy` | string | 数据保留说明（空字符串表示未配置） |
| `accountDeletionGuide` | string | 账号注销说明（空字符串表示未配置） |

#### 3.1.2 小程序端合规信息

```
GET /mp/compliance
```

**响应格式：**

与 `/web/compliance` 完全一致。

#### 3.1.3 小程序隐私政策详情

```
GET /mp/privacy-policy
```

**响应格式：**

```json
{
  "code": 0,
  "data": {
    "content": "隐私政策HTML内容",
    "dataRetentionPolicy": "数据保留说明",
    "accountDeletionGuide": "账号注销说明"
  }
}
```

**说明：** `content` 字段会将 Markdown 转换为 HTML，方便小程序直接渲染。

### 3.2 管理端接口（站长可见）

#### 3.2.1 获取合规配置

```
GET /admin/settings/privacy
```

**权限要求：** `setting:privacy:read`

**响应格式：**

```json
{
  "code": 0,
  "data": {
    "privacyPolicy": "隐私政策内容",
    "filingInfo": "{\"icpCode\":\"京ICP备xxxxxxxx号\",\"filingUrl\":\"https://beian.miit.gov.cn\",\"recordType\":\"个人\"}",
    "contactInfo": "{\"email\":\"contact@example.com\"}",
    "dataRetentionPolicy": "数据保留说明",
    "accountDeletionGuide": "账号注销说明"
  }
}
```

#### 3.2.2 更新合规配置

```
PUT /admin/settings/privacy
```

**权限要求：** `setting:privacy:update`

**请求格式：**

```json
{
  "privacyPolicy": "隐私政策内容（支持Markdown）",
  "filingInfo": "{\"icpCode\":\"京ICP备xxxxxxxx号\",\"filingUrl\":\"https://beian.miit.gov.cn\",\"recordType\":\"个人\"}",
  "contactInfo": "{\"email\":\"contact@example.com\"}",
  "dataRetentionPolicy": "数据保留说明内容",
  "accountDeletionGuide": "账号注销说明内容"
}
```

**字段说明：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `privacyPolicy` | string | 否 | 隐私政策内容 |
| `filingInfo` | string | 否 | 备案信息JSON字符串 |
| `contactInfo` | string | 否 | 联系方式JSON字符串 |
| `dataRetentionPolicy` | string | 否 | 数据保留说明 |
| `accountDeletionGuide` | string | 否 | 账号注销说明 |

**响应格式：**

```json
{
  "code": 0,
  "data": {}
}
```

---

## 4. 数据策略

### 4.1 数据保留策略

| 数据类型 | 保留期限 | 说明 |
|----------|----------|------|
| 隐私政策 | 长期 | 合规配置核心数据 |
| 备案信息 | 长期 | 合规配置核心数据 |
| 联系方式 | 长期 | 合规配置核心数据 |
| 用户行为日志 | 30天 | 用于内容优化，定期清理 |
| 访问日志 | 30天 | 用于运维排查 |
| 错误日志 | 90天 | 用于问题追踪 |

### 4.2 用户数据删除路径

小程序用户可通过以下接口删除账号及相关数据：

```
DELETE /mp/user
```

**删除范围：**
- 用户基础信息（`t_mp_user`）
- 用户收藏（`t_mp_user_favorite`）
- 浏览历史（`t_mp_browse_history`）
- 用户订阅状态（`t_mp_user_subscribe`）
- 用户兴趣画像（`t_mp_user_interest`）
- 用户标签（`t_mp_user_tag`）
- 用户六边形画像（`t_mp_user_profile`）

---

## 5. 前端契约说明（提供给 MacBook）

### 5.1 Web 端展示建议

#### 5.1.1 页脚区域

```
备案信息展示：
┌─────────────────────────────────┐
│ 京ICP备xxxxxxxx号               │
│ 京公网安备xxxxxxxxxxxxx号       │
│ contact@example.com            │
└─────────────────────────────────┘
```

**展示规则：**
- 仅当 `filingInfo` 非空且包含 `icpCode` 时显示备案信息
- 仅当 `contactInfo` 非空时显示联系方式
- 未配置的备案信息不显示（避免占位符影响观感）

#### 5.1.2 隐私政策页面

- 从 `/web/compliance` 获取 `privacyPolicy` 字段
- 将 Markdown 转换为 HTML 渲染
- 页面底部可展示数据保留说明和账号注销说明

### 5.2 小程序端展示建议

#### 5.2.1 设置页

- 提供"隐私政策"入口，跳转至小程序隐私政策页面
- 提供"关于我们"入口，展示备案信息和联系方式
- 提供"账号注销"入口，调用 `DELETE /mp/user`

#### 5.2.2 隐私政策页面

- 使用 `/mp/privacy-policy` 获取内容（已转换为 HTML）
- 展示数据保留说明和账号注销说明

### 5.3 M5 阶段建议

| 阶段 | 建议 |
|------|------|
| M5（契约对齐收口） | 确认前端已适配新的合规字段，确保备案信息、联系方式、数据保留说明、账号注销说明在 Web 和小程序中正确展示 |

---

## 6. 代码实现说明

### 6.1 Service 层

| 文件 | 方法 | 说明 |
|------|------|------|
| `internal/application/setting/service.go` | `GetPublicCompliance` | 返回读者可见的合规字段 |
| | `GetPrivacyConfig` | 返回管理端完整合规配置 |
| | `UpdatePrivacyConfig` | 更新合规配置，自动清理缓存 |

### 6.2 Repository 层

| 文件 | 方法 | 说明 |
|------|------|------|
| `internal/infrastructure/repository/mysqlrepo/setting_repo.go` | `GetPrivacyConfig` | 查询 `t_blog_compliance_config`，兼容旧表回退 |
| | `UpdatePrivacyConfig` | 更新 `t_blog_compliance_config`，支持所有合规字段 |

### 6.3 Handler 层

| 文件 | 方法 | 路由 |
|------|------|------|
| `internal/interfaces/http/handler/web_handler.go` | `WebCompliance` | `GET /web/compliance` |
| `internal/interfaces/http/handler/mp_handler.go` | `MpCompliance` | `GET /mp/compliance` |
| | `MpPrivacyPolicy` | `GET /mp/privacy-policy` |
| `internal/interfaces/http/handler/admin_setting_handler.go` | `AdminGetPrivacyConfig` | `GET /admin/settings/privacy` |
| | `AdminUpdatePrivacyConfig` | `PUT /admin/settings/privacy` |

---

## 7. 验收对照

| 验收标准 | 达成情况 |
|----------|----------|
| Web 和小程序都能读取必要合规信息 | 达成 — `/web/compliance` 和 `/mp/compliance` 已实现 |
| 用户删除路径和说明清晰 | 达成 — `DELETE /mp/user` 和 `accountDeletionGuide` 字段 |
| 没有引入平台化、商业化字段 | 达成 — 仅包含合规相关字段 |
| 管理端可更新合规配置 | 达成 — `PUT /admin/settings/privacy` 已实现 |
| 缓存更新机制正常 | 达成 — 更新后自动清理 `blog:setting:*` 缓存 |
| 兼容旧部署环境 | 达成 — `t_blog_compliance_config` 不存在时回退到 `t_blog_privacy_config` |

---

## 8. 风险与后续建议

### 8.1 当前风险

| 风险 | 等级 | 说明 |
|------|------|------|
| 前端未适配新字段 | 低 | 接口已就绪，前端按契约适配即可 |
| 备案信息格式错误 | 低 | JSON 格式错误会导致解析失败，建议前端做好容错处理 |

### 8.2 后续建议

1. **M5 阶段**：MacBook 完成前端合规信息展示适配
2. **数据验证**：建议在管理端添加合规配置字段的格式校验（如 JSON 格式校验）
3. **合规审查**：建议定期审查隐私政策和数据保留说明内容，确保符合法规要求

---

## 9. 文档版本

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-07-14 | L4 初始版本，完成合规配置与个人备案友好接口契约说明 |