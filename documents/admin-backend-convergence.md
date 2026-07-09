# 站长后台收敛方案（L3 交付物）

## 1. 文档定位

本文档为 `implementation-tasks.md` 中 L3 任务的核心交付物，面向：

- **后端维护者**：明确后台能力保留/冻结策略、权限收敛方向
- **前端（MacBook）开发者**：提供后台菜单/页面的保留/隐藏契约，指导 M2/M5 阶段的界面收敛
- **陛下审核**：验证后台收敛策略是否符合"站长后台"定位与个人备案边界

上位约束：

- [plan.md](file:///c:/workspace/sanmoo-blog/documents/plan.md)
- [business-boundary.md](file:///c:/workspace/sanmoo-blog/documents/business-boundary.md)
- [frozen-capabilities.md](file:///c:/workspace/sanmoo-blog/documents/frozen-capabilities.md)
- [api-domain-inventory.md](file:///c:/workspace/sanmoo-blog/documents/api-domain-inventory.md)

---

## 2. 收敛原则

| 原则 | 说明 |
|------|------|
| 内容优先 | 内容管理相关能力优先级最高，必须完整保留 |
| 权限最小化 | 用户角色收敛为"站长/编辑"两级，不再扩展复杂 RBAC |
| 运维适度 | 维护工具只保留"必要可用"，不追求企业级运维面板 |
| 不粗暴删除 | 保留接口签名，避免前端直接崩溃 |
| 标记清晰 | 冻结点在代码注释中以 `FROZEN (L3):` 标记 |
| 渐进收敛 | 先标记冻结，前端隐藏入口，后续阶段评估完全移除 |

---

## 3. 后台功能保留矩阵

### 3.1 高频保留项（核心功能，持续维护）

| 模块 | 功能项 | 说明 | 权限标识 |
|------|--------|------|----------|
| **文章管理** | 文章CRUD | 文章创建、编辑、删除、状态管理 | article:* |
| | 文章列表/详情 | 文章列表查询、详情查看 | article:list, article:detail |
| | 批量操作 | 批量更新状态、批量删除 | article:status, article:delete |
| | 导出文章 | 文章数据导出 | article:export |
| **分类管理** | 分类CRUD | 分类创建、编辑、删除 | category:* |
| **标签管理** | 标签CRUD | 标签创建、编辑、删除 | tag:* |
| **专题管理** | 专题CRUD | 专题创建、编辑、删除 | topic:* |
| | 专题文章管理 | 专题关联文章、排序 | topic:articles |
| **友情链接** | 链接CRUD | 友情链接创建、编辑、删除 | link:* |
| **文件管理** | 文件上传/列表/删除 | 媒体资源管理 | file:* |
| **站点配置** | 核心配置 | 站点品牌、作者信息 | setting:core:* |
| | 合规配置 | 隐私政策、备案信息 | setting:privacy:* |
| | 渠道配置 | Web/小程序渠道、社交链接 | setting:social:* |
| | 基础设施配置 | 搜索、存储、邮件配置 | setting:search:*, setting:storage:*, setting:email:* |
| | 搜索同步 | MeiliSearch同步 | setting:search |
| **数据看板** | 仪表盘总览 | 内容表现统计 | dashboard:read |
| | 内容统计 | PV、分类/标签/专题统计 | dashboard:statistics |
| | 内容趋势 | 文章阅读趋势、发布热力图 | dashboard:statistics |
| **当前用户** | 权限查询 | 获取当前用户权限 | 无（免权限） |
| | 菜单查询 | 获取当前用户菜单 | 无（免权限） |

### 3.2 低频冻结项（平台化能力，不再扩展）

| 模块 | 功能项 | 说明 | 冻结原因 | 权限标识 |
|------|--------|------|----------|----------|
| **用户管理** | 用户CRUD | 用户创建、编辑、删除 | 平台化扩张，个人站点无需多用户管理 | user:* |
| | 重置密码 | 用户密码重置 | 平台化扩张 | user:password:reset |
| | 状态切换 | 用户启用/禁用 | 平台化扩张 | user:status |
| | 角色分配 | 用户角色分配 | 平台化扩张 | user:role |
| **角色管理** | 角色CRUD | 角色创建、编辑、删除 | 收敛为两级角色，不再扩展 | role:* |
| | 权限分配 | 角色权限分配 | 收敛为两级角色 | role:permission |
| **权限管理** | 权限CRUD | 权限创建、编辑、删除 | 不再扩展权限维度 | permission:* |
| | 权限树 | 权限树结构查询 | 不再扩展权限维度 | permission:list |
| **缓存管理** | 清理缓存 | Redis缓存清理 | 低频运维，个人站点可通过重启解决 | cache:* |
| | 预热缓存 | 缓存预热 | 低频运维 | cache:warmup |
| | 缓存统计 | 缓存状态统计 | 低频运维 | cache:stats |
| **备份管理** | 数据导出 | 数据备份导出 | 低频运维，个人站点可使用数据库备份 | backup:* |
| | 备份列表 | 备份文件列表 | 低频运维 | backup:list |
| | 下载备份 | 下载备份文件 | 低频运维 | backup:download |
| **小程序用户管理** | 用户列表/详情 | 小程序用户查看 | 重运营画像，个人站点无需用户运营 | mpuser:* |
| | 画像查看/生成 | 用户六边形画像 | 重运营画像，已在 L2 冻结 | mpuser:profile |
| | 标签查看/生成 | 用户标签管理 | 重运营画像，已在 L2 冻结 | mpuser:tags |
| **数据维护** | 维护统计 | 系统维护统计 | 低频运维 | maintenance:* |
| | 日志清理 | 日志清理任务 | 低频运维，由定时任务替代 | maintenance:cleanup |
| **仪表盘（运维）** | 访客记录管理 | 访客记录删除、清空 | 低频运维 | dashboard:visitors:* |
| | 错误日志管理 | 错误日志导入/导出/删除 | 低频运维 | dashboard:errors:* |
| | 小程序用户增长 | 用户增长统计 | 重运营画像，不做用户增长分析 | dashboard:statistics |
| **配置管理（运维）** | 配置导入导出 | 配置数据导入导出 | 低频运维 | setting:export, setting:import |

---

## 4. 权限收敛方案

### 4.1 两级角色定义

#### 角色一：站长（Admin）

| 属性 | 值 |
|------|-----|
| 角色名 | admin |
| 描述 | 站点所有者，拥有全部权限 |
| 权限范围 | 所有后台功能，包括内容管理、配置管理、系统维护 |
| 适用场景 | 个人站长本人 |

**站长权限清单**（保留的权限标识）：

```
article:*, tag:*, category:*, topic:*, link:*
file:*, setting:*, dashboard:*
```

#### 角色二：编辑（Editor）

| 属性 | 值 |
|------|-----|
| 角色名 | editor |
| 描述 | 内容编辑者，仅拥有内容管理权限 |
| 权限范围 | 文章、分类、标签、专题、友情链接、文件管理 |
| 适用场景 | 协作编辑（如有） |

**编辑权限清单**：

```
article:list, article:detail, article:create, article:update, article:status
tag:list, tag:create, tag:update, tag:delete
category:list, category:create, category:update, category:delete
topic:list, topic:create, topic:update, topic:delete, topic:articles
link:list, link:create, link:update, link:delete
file:list, file:upload, file:delete
```

### 4.2 权限收敛策略

| 策略 | 说明 |
|------|------|
| 冻结角色管理 | 不再允许创建新角色，仅保留 admin 和 editor |
| 冻结权限管理 | 不再允许创建/修改权限，权限维度固定 |
| 冻结用户管理 | 不再允许创建/修改后台用户，仅保留基础查看 |
| 管理员豁免 | admin 角色自动拥有所有权限，不受权限配置限制 |
| 渐进移除 | 待前端隐藏入口后，后续阶段可考虑代码层移除 |

### 4.3 权限模型收敛前后对比

| 维度 | 收敛前 | 收敛后 |
|------|--------|--------|
| 角色数量 | 可自定义，理论无限 | 固定两级：admin、editor |
| 权限维度 | 细粒度 CRUD 权限树 | 粗粒度功能模块权限 |
| 权限管理 | 支持增删改查 | 冻结，不再扩展 |
| 用户管理 | 支持多用户管理 | 冻结，仅保留基础查看 |
| 适用场景 | 企业级多租户平台 | 个人站长单站点 |

---

## 5. 低频后台能力冻结说明

### 5.1 用户管理模块

| 接口 | 方法 | 冻结策略 | 代码位置 |
|------|------|----------|----------|
| `/admin/users` | GET | 冻结（只读保留） | admin_handler.go |
| `/admin/users` | POST | 冻结 | admin_handler.go |
| `/admin/users/:id` | PUT | 冻结 | admin_handler.go |
| `/admin/users/:id` | DELETE | 冻结 | admin_handler.go |
| `/admin/users/:id/password` | PUT | 冻结 | admin_handler.go |
| `/admin/users/:id/status` | PUT | 冻结 | admin_handler.go |
| `/admin/users/:id/roles` | PUT | 冻结 | admin_handler.go |

### 5.2 角色管理模块

| 接口 | 方法 | 冻结策略 | 代码位置 |
|------|------|----------|----------|
| `/admin/roles` | GET | 冻结（只读保留） | admin_handler.go |
| `/admin/roles` | POST | 冻结 | admin_handler.go |
| `/admin/roles/:id` | PUT | 冻结 | admin_handler.go |
| `/admin/roles/:id` | DELETE | 冻结 | admin_handler.go |
| `/admin/roles/:id/permissions` | PUT | 冻结 | admin_handler.go |

### 5.3 权限管理模块

| 接口 | 方法 | 冻结策略 | 代码位置 |
|------|------|----------|----------|
| `/admin/permissions` | GET | 冻结（只读保留） | admin_handler.go |
| `/admin/permissions/tree` | GET | 冻结（只读保留） | admin_handler.go |
| `/admin/permissions` | POST | 冻结 | admin_handler.go |
| `/admin/permissions/:id` | PUT | 冻结 | admin_handler.go |
| `/admin/permissions/:id` | DELETE | 冻结 | admin_handler.go |

### 5.4 缓存管理模块

| 接口 | 方法 | 冻结策略 | 代码位置 |
|------|------|----------|----------|
| `/admin/cache/clear` | POST | 冻结 | admin_handler.go |
| `/admin/cache/warmup` | POST | 冻结 | admin_handler.go |
| `/admin/cache/stats` | GET | 冻结 | admin_handler.go |

### 5.5 备份管理模块

| 接口 | 方法 | 冻结策略 | 代码位置 |
|------|------|----------|----------|
| `/admin/backup/export` | POST | 冻结 | admin_handler.go |
| `/admin/backup/list` | GET | 冻结 | admin_handler.go |
| `/admin/backup/download/:fileName` | GET | 冻结 | admin_handler.go |
| `/admin/backup/:fileName` | DELETE | 冻结 | admin_handler.go |
| `/admin/backup/stats` | GET | 冻结 | admin_handler.go |

### 5.6 数据维护模块

| 接口 | 方法 | 冻结策略 | 代码位置 |
|------|------|----------|----------|
| `/admin/maintenance/stats` | GET | 冻结 | admin_handler.go |
| `/admin/maintenance/cleanup-logs` | POST | 冻结 | admin_handler.go |

### 5.7 代码冻结标记

所有冻结点在代码中以 `FROZEN (L3):` 注释标记，可检索以下文件：

| 文件 | 标记内容 |
|------|----------|
| `sanmoo-server-go/internal/application/role/service.go` | 角色管理相关方法 |
| `sanmoo-server-go/internal/application/permission/service.go` | 权限管理相关方法 |
| `sanmoo-server-go/internal/application/dashboard/service.go` | 低频运维能力相关方法 |
| `sanmoo-server-go/internal/interfaces/http/router/router.go` | 冻结接口路由 |

---

## 6. 前端契约说明（提供给 MacBook）

### 6.1 M2 阶段建议（后台菜单收敛）

#### 6.1.1 完整隐藏的菜单

以下菜单入口应在前端完全隐藏：

- **用户管理**：完整隐藏（`/admin/users` 相关页面）
- **角色管理**：完整隐藏（`/admin/roles` 相关页面）
- **权限管理**：完整隐藏（`/admin/permissions` 相关页面）
- **小程序用户管理**：完整隐藏（`/admin/mp-users` 相关页面）
- **缓存管理**：完整隐藏（`/admin/cache` 相关页面）
- **备份管理**：完整隐藏（`/admin/backup` 相关页面）
- **数据维护**：完整隐藏（`/admin/maintenance` 相关页面）

#### 6.1.2 弱化的页面区域

以下页面区域应在前端弱化显示或隐藏操作按钮：

| 页面 | 弱化内容 | 建议处理 |
|------|----------|----------|
| 仪表盘 | 访客记录管理（删除、批量删除、清空） | 隐藏操作按钮，仅保留查看 |
| | 错误日志管理（导入、导出、删除、清空） | 隐藏操作按钮，仅保留查看 |
| | 小程序用户增长图表 | 隐藏该图表区域 |
| 设置中心 | 配置导入/导出功能 | 隐藏导入/导出按钮 |

### 6.2 M5 阶段建议（契约对齐收口）

| 阶段 | 建议 |
|------|------|
| M5（契约对齐收口） | 确认前端不再调用冻结接口后，后端可在后续阶段评估是否移除路由 |
| 后续评估 | 建议在 L5 阶段确认前端已完全不再调用冻结接口后，再考虑代码层移除 |

### 6.3 接口响应契约

冻结接口的**响应格式保持不变**，但前端应停止调用以下接口：

#### 6.3.1 用户管理接口

```
POST /admin/users
PUT /admin/users/:id
DELETE /admin/users/:id
PUT /admin/users/:id/password
PUT /admin/users/:id/status
PUT /admin/users/:id/roles
DELETE /admin/users/batch-delete
```

#### 6.3.2 角色管理接口

```
POST /admin/roles
PUT /admin/roles/:id
DELETE /admin/roles/:id
PUT /admin/roles/:id/permissions
```

#### 6.3.3 权限管理接口

```
POST /admin/permissions
PUT /admin/permissions/:id
DELETE /admin/permissions/:id
```

#### 6.3.4 运维管理接口

```
POST /admin/cache/clear
POST /admin/cache/warmup
GET /admin/cache/stats
POST /admin/backup/export
GET /admin/backup/list
GET /admin/backup/download/:fileName
DELETE /admin/backup/:fileName
GET /admin/backup/stats
GET /admin/maintenance/stats
POST /admin/maintenance/cleanup-logs
DELETE /admin/dashboard/visitors/:id
DELETE /admin/dashboard/visitors/batch-delete
DELETE /admin/dashboard/visitors/clear
DELETE /admin/dashboard/errors/:id
DELETE /admin/dashboard/errors/batch-delete
DELETE /admin/dashboard/errors/clear
POST /admin/dashboard/errors/import
GET /admin/dashboard/errors/export
POST /admin/settings/export
POST /admin/settings/import
```

---

## 7. 验收对照

| 验收标准 | 达成情况 |
|----------|----------|
| 内容管理相关能力优先级最高 | 达成 — 文章、分类、标签、专题、链接、文件管理全部保留 |
| 平台化运维能力不再继续扩张 | 达成 — 用户管理、角色权限、缓存管理、备份管理已冻结 |
| 权限模型有清晰收敛方向 | 达成 — 收敛为站长/编辑两级，不再扩展复杂 RBAC |
| 不修改任何前端、小程序、README、部署文件 | 达成 — 仅修改后端代码与文档 |
| 代码中明确标记冻结点 | 达成 — `FROZEN (L3):` 标记已添加至相关文件 |
| 有可供前端读取的契约说明 | 达成 — 本文档第 6 章提供完整前端契约 |

---

## 8. 风险与后续建议

### 8.1 当前风险

| 风险 | 等级 | 说明 |
|------|------|------|
| 前端仍调用冻结接口 | 低 | 接口仍可调用但属于冻结状态，不会崩溃 |
| 历史角色/权限数据残留 | 低 | `t_role`、`t_permission` 等表仍有历史数据，不影响核心功能 |
| 管理员权限未受影响 | 无风险 | admin 角色仍拥有全部权限，不受冻结影响 |

### 8.2 后续建议

1. **L5 阶段**：评估冻结接口的使用情况，确认无前端依赖后可考虑代码层移除
2. **前端配合**：MacBook 在 M2 阶段隐藏管理端入口后，可显著降低冻结接口的调用量
3. **监控**：建议在 L5 阶段确认前端已完全不再调用冻结接口后，再考虑代码层移除
4. **数据清理**：L5 阶段可评估是否清理 `t_role`、`t_permission`、`t_role_permission` 表中多余的角色和权限数据

---

## 9. 文档版本

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-07-09 | L3 初始版本，完成站长后台收敛方案与前端契约说明 |