# Sanmoo Blog 架构优化工作计划

> 背景：Sanmoo Blog 为个人资质备案的个人博客，当前仅 1 个管理员用户。  
> 目标：移除冻结功能、简化过度设计、精简数据库和代码，降低维护成本。

---

## 一、当前架构诊断摘要

| 维度 | 现状 | 目标 |
|------|------|------|
| 数据库表 | 27 张 | 18 张（-9） |
| 后端 application 包 | 20 个 | 14 个（-6） |
| 权限记录 | 143 条 perm_key | 0（改为 is_admin 单字段） |
| 推荐策略 | 3 种（rule / weighted / cf） | 1 种（rule） |
| 用户画像表 | 4 张（behavior / interest / tag / profile） | 0 |
| 冻结模块 | 6 个（路由仍存活） | 0 |

---

## 二、优化任务拆解

### P0：简化 RBAC 权限系统（预计收益最大）

**目标**：将五表 RBAC 替换为 `t_user.is_admin` 单字段，移除全部权限中间件。

**后端改动**：

| 子任务 | 涉及文件 | 操作 |
|--------|---------|------|
| `t_user` 表新增 `is_admin` 字段 | `migrations/update.sql` | 新增迁移 |
| 新增 `RequireAdmin` 中间件替代 `RequirePerm` | `middleware/perm_middleware.go` | 重写 |
| 删除 `application/permission/` | `service.go` | 删除包 |
| 删除 `application/role/` | `service.go` | 删除包 |
| 删除 `domain/permission/` | `model.go`、`repository.go` | 删除包 |
| 删除 `domain/role/` | `model.go`、`repository.go` | 删除包 |
| 删除 `handler/admin_permission.go` | 整个文件 | 删除 |
| 删除 `handler/admin_role.go` | 整个文件 | 删除 |
| 修改 `router/router.go`，移除所有 `RequirePerm` 调用 | 路由注册 | 修改 |
| 修改 `bootstrap/app.go`，移除 permission/role 初始化 | 依赖注入 | 修改 |
| 删除 `repository/mysqlrepo/permission_repo.go` | 整个文件 | 删除 |
| 删除 `repository/mysqlrepo/role_repo.go` | 整个文件 | 删除 |

**前端改动**：

| 子任务 | 涉及文件 | 操作 |
|------|---------|------|
| 删除 `usePermStore.ts` | `src/store/usePermStore.ts` | 删除 |
| 删除 `usePermission.ts` | `src/hooks/usePermission.ts` | 删除 |
| 删除 `PermGuard.tsx` | `src/components/admin/PermGuard.tsx` | 删除 |
| 删除 `permission-api.ts` | `src/services/blog/permission-api.ts` | 删除 |
| 删除 `role-api.ts` | `src/services/blog/role-api.ts` | 删除 |
| `Admin.tsx` 菜单改为纯静态配置 | `src/pages/Admin.tsx` | 简化 |
| 移除 `PermGuard` 引用 | 所有页面组件 | 清理 |

**数据库改动**：

```sql
-- 新增字段
ALTER TABLE t_user ADD COLUMN is_admin TINYINT(1) NOT NULL DEFAULT 0;
UPDATE t_user SET is_admin = 1 WHERE id = 1;  -- 现有用户设为 admin

-- 删除表（待确认无依赖后执行）
DROP TABLE IF EXISTS t_role_permission;
DROP TABLE IF EXISTS t_user_role;
DROP TABLE IF EXISTS t_permission;
DROP TABLE IF EXISTS t_role;
```

---

### P1：删除冻结模块代码

**目标**：彻底移除 6 个已冻结模块的后端路由、handler、service。

| 模块 | 冻结级别 | 删除内容 |
|------|----------|---------|
| 用户管理 | L3 | `handler/admin_user.go`、`application/user/`、`domain/user/`（保留 auth 登录模型） |
| 缓存管理 | L3 | `handler/cache.go`、`application/cache/`、路由 |
| 备份管理 | L3 | `handler/backup.go`、`application/backup/`、路由 |
| 数据维护 | L3 | `handler/admin_maintenance.go`、`application/maintenance/`、路由 |
| 角色管理 | L3 | 随 P0 一并删除 |
| 权限管理 | L3 | 随 P0 一并删除 |

**注意**：`application/cache/` 删除后，`infrastructure/cache/` 中的 Redis 缓存核心逻辑保留不变（业务缓存仍在使用）。

---

### P2：降级推荐系统

**目标**：将 3 策略推荐降级为单一规则策略。

| 子任务 | 操作 |
|------|------|
| 删除 `cf_strategy.go` | 协同过滤策略 |
| 删除 `weighted_strategy.go` | 加权策略 |
| 删除 `registry.go` | 策略注册表（不再需要多策略管理） |
| 简化 `strategy.go` | 只保留 Strategy 接口或直接内联 |
| 修改 `handler/mp.go` | 推荐接口直接调用 `RuleStrategy` |
| 配置项 `recommend_strategy` 可保留但忽略 | 向后兼容 |

---

### P3：删除用户画像系统

**目标**：移除小程序用户画像相关 4 张表和全部计算逻辑。

| 子任务 | 涉及文件 |
|------|---------|
| 删除 `t_mp_user_behavior` 表 | 数据库迁移 |
| 删除 `t_mp_user_interest` 表 | 数据库迁移 |
| 删除 `t_mp_user_tag` 表 | 数据库迁移 |
| 删除 `t_mp_user_profile` 表 | 数据库迁移 |
| 删除 `t_mp_reco_exposure` 表 | 数据库迁移 |
| 删除 `t_mp_user_subscribe` 表 | 数据库迁移（如未使用订阅消息） |
| 删除 `subscribe_service.go` | `application/mpuser/subscribe_service.go` |
| 删除 `models.go` 中对应 GORM 模型 | `repository/mysqlrepo/models.go` |
| 删除 `mp_user_admin_repo.go` 中画像/标签/兴趣方法 | 大幅简化 |
| 删除 `domain/mpuser/model.go` 中对应结构体 | 清理 |
| 删除 `handler/mp_user_admin.go` 中画像/标签相关路由 | 清理 |
| 删除 `router/router.go` 中对应路由 | 清理 |

---

### P4：清理无用数据库表

**目标**：删除从未使用或数据量极少的表。

| 表名 | 删除原因 |
|------|---------|
| `t_search_history` | 仅 3 条记录，搜索历史功能未启用 |
| `t_third_party_log` | 空表，从未写入 |

---

### P5：可选优化（低优先级）

| 优化项 | 说明 |
|------|------|
| 定时发布调度器轮询频率从 1 分钟改为 5 分钟 | `scheduler/publish_scheduler.go` |
| 前端 `Visitors.tsx` 重命名为更清晰的名称 | 避免与已删除的 `t_visitor_record` 表混淆 |
| 统一 `created_by`/`updated_by` 字段为空 | 不再需要审计追踪 |

---

## 三、执行顺序与依赖

```
P0（简化 RBAC）
  ├── 依赖：无
  └── 产出：删除 4 张表 + 6 个后端包 + 4 个前端文件

P1（删除冻结模块）
  ├── 依赖：P0（角色/权限管理已在 P0 删除）
  └── 产出：删除 4 个 service 包 + 对应 handler

P2（降级推荐）
  ├── 依赖：无
  └── 产出：删除 2 个策略文件 + 1 个注册表

P3（删除用户画像）
  ├── 依赖：P2（推荐系统简化后，画像数据无消费方）
  └── 产出：删除 6 张表 + subscribe_service

P4（清理无用表）
  ├── 依赖：P3
  └── 产出：删除 2 张表

P5（可选优化）
  ├── 依赖：P4
  └── 产出：小幅调整
```

---

## 四、最终目标架构

### 数据库：18 张表

```
t_access_log           — 访问日志
t_error_log            — 错误日志
t_article              — 文章
t_article_content      — 文章内容
t_article_category_rel — 文章-分类关联
t_article_tag_rel      — 文章-标签关联
t_article_topic_rel    — 文章-专题关联
t_category             — 分类
t_tag                  — 标签
t_topic                — 专题
t_link                 — 友情链接
t_blog_brand_config    — 站点品牌配置
t_blog_channel_config  — 渠道配置
t_blog_compliance_config— 合规配置
t_blog_inf_config      — 基础设施配置
t_mp_user              — 小程序用户
t_mp_browse_history    — 浏览历史
t_mp_user_favorite     — 收藏
t_statistics_article_pv— 文章 PV 统计
t_user                 — 管理员（简化为 username + password_hash + is_admin）
```

### 后端：14 个 application 包

```
article、auth、category、dashboard、file、link、
mpuser、setting、tag、topic、visitor、scheduler、
recommendation（仅 rule）、cache（infrastructure 层）
```

---

## 五、风险与回滚策略

| 风险 | 应对 |
|------|------|
| 删除 RBAC 后认证中间件异常 | `RequireAdmin` 逻辑简单，仅检查 `is_admin` 字段，测试覆盖 |
| 删除用户画像表影响小程序端 | 小程序端 API 仅查询用户基本信息，不依赖画像数据 |
| 数据库迁移不可逆 | 迁移前备份，迁移脚本写在 `migrations/` 目录中保留记录 |

---

## 六、验收标准

1. 所有冻结模块的后端路由不再注册
2. 前端管理后台菜单正常显示，无报错
3. 文章 CRUD、设置、文件管理等核心功能正常
4. 小程序端文章浏览、收藏、历史记录正常
5. 数据库表数量从 27 降至 18
6. 后端编译无错误，单元测试通过
7. 前端编译无错误，无 TypeScript 类型错误