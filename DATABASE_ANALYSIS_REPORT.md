# 数据库设计分析报告

## 一、现有数据库表结构概览

### 1.1 核心业务表

| 表名 | 用途 | 使用状态 |
|------|------|----------|
| `t_user` | 后台管理员用户 | ✅ 使用中 |
| `t_role` | 用户角色 | ⚠️ 部分使用 |
| `t_user_role` | 用户-角色关联 | ⚠️ 部分使用 |
| `t_tag` | 文章标签 | ✅ 使用中 |
| `t_category` | 文章分类 | ✅ 使用中 |
| `t_article` | 文章基本信息 | ✅ 使用中 |
| `t_article_content` | 文章内容（分离存储） | ✅ 使用中 |
| `t_article_category_rel` | 文章-分类关联 | ✅ 使用中 |
| `t_article_tag_rel` | 文章-标签关联 | ✅ 使用中 |
| `t_topic` | 专题/合集 | ✅ 使用中 |
| `t_article_topic_rel` | 文章-专题关联 | ✅ 使用中 |
| `t_link` | 友情链接 | ✅ 使用中 |

### 1.2 用户行为表

| 表名 | 用途 | 使用状态 |
|------|------|----------|
| `t_mp_user` | 微信小程序用户 | ✅ 使用中 |
| `t_mp_user_favorite` | 小程序用户收藏 | ✅ 使用中 |
| `t_mp_user_behavior` | 小程序用户行为 | ✅ 使用中 |
| `t_mp_user_tag` | 小程序用户标签 | ✅ 使用中 |
| `t_mp_user_interest` | 小程序用户兴趣 | ✅ 使用中 |
| `t_mp_user_profile` | 小程序用户画像 | ✅ 使用中 |
| `t_mp_user_subscribe` | 小程序用户订阅 | ✅ 使用中 |

### 1.3 统计与日志表

| 表名 | 用途 | 使用状态 |
|------|------|----------|
| `t_statistics_article_pv` | 文章 PV 统计 | ✅ 使用中 |
| `t_search_history` | 搜索历史 | ✅ 使用中 |
| `t_access_log` | 访问日志 | ✅ 使用中 |
| `t_error_log` | 错误日志 | ✅ 使用中 |
| `t_visitor_record` | 访客记录 | ❌ **未使用** |

---

## 二、问题分析

### 2.1 未使用的表

#### 问题：`t_visitor_record` 表完全未使用

**证据**：全局搜索 `t_visitor_record` 或 `tVisitor` 仅在 `models.go` 中出现，无任何查询或写入逻辑。

```go
// models.go 中定义了但从未使用
type tVisitor struct {
    ID        uint64    `gorm:"column:id"`
    Visitor   string    `gorm:"column:visitor"`
    IPAddress []byte    `gorm:"column:ip_address"`
    IPRegion  string    `gorm:"column:ip_region"`
    VisitTime time.Time `gorm:"column:visit_time"`
    IsNotify  uint8     `gorm:"column:is_notify"`
}
```

**影响**：
- 表结构冗余，增加维护成本
- 与 `t_access_log` 功能重叠（都记录访客信息）

**建议方案**：
1. **废弃删除**：如果确认不再需要，删除该表定义和迁移文件
2. **合并到 `t_access_log`**：`t_access_log` 已包含完整的访问信息，`t_visitor_record` 是冗余的

---

### 2.2 设计不合理的表

#### 问题1：`t_article_content` 缺少唯一性约束

**证据**：`t_article_content` 的唯一约束应该是 `article_id`，但当前模型定义中没有指定。

```go
type tArticleContent struct {
    ID        uint64 `gorm:"column:id;primaryKey"`
    ArticleID uint64 `gorm:"column:article_id"`
    Content   string `gorm:"column:content"`
}
```

**影响**：
- 理论上可能存在同一文章多条内容记录
- `UpdateArticle` 中使用 `article_id` 更新是假设唯一，但数据库层面未保证

**建议方案**：
```sql
ALTER TABLE t_article_content ADD UNIQUE KEY uk_article_id (article_id);
```

---

#### 问题2：`t_visitor_record` 与 `t_access_log` 功能重叠

**证据**：两张表都记录访问相关信息，但 `t_access_log` 功能更完整，包含 TraceID、请求详情、响应信息等。

| 字段 | t_visitor_record | t_access_log |
|------|------------------|--------------|
| 访客标识 | visitor | visitor_user_id + visitor_name |
| IP 地址 | ip_address | ip_address |
| 访问时间 | visit_time | request_time |
| 请求信息 | ❌ | request_method, request_url, request_path |
| 响应信息 | ❌ | response_status, response_time |
| 错误信息 | ❌ | is_error, error_id |
| 用户代理 | ❌ | user_agent |

**建议方案**：删除 `t_visitor_record`，统一使用 `t_access_log`。

---

#### 问题3：IP 地址存储格式不一致

**证据**：`t_visitor_record` 和 `t_access_log`/`t_error_log` 都使用 `[]byte` 存储 IP，但：
- `t_visitor_record` 的 `IPRegion` 字段未被使用
- 查询时需要转换（`toIPString` 函数），可读性差

**建议方案**：
1. 统一使用 `VARCHAR(45)` 存储 IP（IPv6 需要最多 45 字符）
2. 删除 `t_visitor_record` 后，仅保留 `t_access_log` 的 IP 字段
3. 如果需要地区信息，建议通过 IP 库实时查询或存储单独的地区表

---

#### 问题4：`t_search_history` 缺少数据清理机制

**证据**：`RecordSearchHistory` 只写入不清理，`GetHotSearchKeywords` 查询近 7 天数据，但历史数据会无限增长。

**影响**：
- 表数据量持续增长，影响查询性能
- 无过期数据清理策略

**建议方案**：
1. 添加定时任务清理 30 天前的历史数据
2. 或者添加 TTL（MySQL 8.0+ 支持表达式索引配合分区）

```sql
-- 添加索引优化查询
ALTER TABLE t_search_history ADD INDEX idx_search_time (search_time);

-- 清理脚本示例（建议通过 cron 定时执行）
DELETE FROM t_search_history WHERE search_time < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

---

#### 问题5：`t_user_role` 插入字段不完整

**证据**：创建用户时插入 `t_user_role` 使用了动态 map，包含 `created_by` 和 `updated_by`，但模型定义中没有这些字段。

```go
// user_repo.go:102
r.db.WithContext(ctx).Table("t_user_role").Create(map[string]any{
    "user_id": model.ID, 
    "role_id": u.RoleID, 
    "created_by": "system", 
    "updated_by": "system"
})
```

**影响**：
- 如果数据库表中没有 `created_by`/`updated_by` 字段，会导致插入失败或警告
- 模型定义与实际数据库结构不一致

**建议方案**：
1. 如果表中有这些字段，更新模型定义
2. 如果表中没有，移除代码中的这些字段

---

### 2.3 缺少索引的表

#### 问题1：`t_article_tag_rel` 和 `t_article_category_rel` 缺少联合索引

**证据**：这两张关联表经常按 `article_id` 或 `tag_id`/`category_id` 查询，但没有索引。

**建议方案**：
```sql
-- t_article_tag_rel
ALTER TABLE t_article_tag_rel ADD INDEX idx_article_id (article_id);
ALTER TABLE t_article_tag_rel ADD INDEX idx_tag_id (tag_id);
ALTER TABLE t_article_tag_rel ADD UNIQUE KEY uk_article_tag (article_id, tag_id);

-- t_article_category_rel  
ALTER TABLE t_article_category_rel ADD INDEX idx_article_id (article_id);
ALTER TABLE t_article_category_rel ADD INDEX idx_category_id (category_id);
ALTER TABLE t_article_category_rel ADD UNIQUE KEY uk_article_category (article_id, category_id);
```

---

#### 问题2：`t_article_topic_rel` 缺少联合索引

**证据**：专题关联查询频繁，但缺少必要索引。

**建议方案**：
```sql
ALTER TABLE t_article_topic_rel ADD INDEX idx_article_id (article_id);
ALTER TABLE t_article_topic_rel ADD INDEX idx_topic_id (topic_id);
ALTER TABLE t_article_topic_rel ADD UNIQUE KEY uk_article_topic (article_id, topic_id);
```

---

#### 问题3：`t_statistics_article_pv` 缺少联合索引

**证据**：`IncreaseReadAndPV` 使用 `article_id + pv_date` 查询，但模型中没有索引。

**建议方案**：
```sql
ALTER TABLE t_statistics_article_pv ADD UNIQUE KEY uk_article_date (article_id, pv_date);
ALTER TABLE t_statistics_article_pv ADD INDEX idx_pv_date (pv_date);
```

---

#### 问题4：`t_mp_user_favorite` 缺少联合索引

**证据**：收藏查询使用 `openid + article_id`，但没有唯一约束。

**建议方案**：
```sql
ALTER TABLE t_mp_user_favorite ADD UNIQUE KEY uk_openid_article (openid, article_id);
ALTER TABLE t_mp_user_favorite ADD INDEX idx_openid (openid);
```

---

### 2.4 类型设计不一致

#### 问题：状态字段类型不统一

**证据**：
- `t_user.status` 使用 `string`（"ENABLED"/"DISABLED"）
- `t_topic.status` 使用 `uint8`（0/1）
- `t_mp_user.status` 使用 `uint8`（0/1）
- `t_link.is_active` 使用 `bool`

**影响**：
- 代码可读性差，需要记忆不同的状态类型
- 前端对接时需要处理不同类型

**建议方案**：统一使用 `uint8` 或 `TINYINT(1)` 表示状态：
- 0 = 禁用/删除
- 1 = 启用/正常

---

### 2.5 软删除设计不一致

**证据**：
- `t_tag`、`t_category` 有 `deleted_at` 字段（软删除）
- `t_article`、`t_topic` 使用 `is_published`/`status` 代替删除
- `t_user` 没有软删除

**影响**：
- 删除策略不统一
- `t_topic` 的删除只是将 `status` 设为 0，但数据仍在表中
- `t_article` 删除是物理删除，不可恢复

**建议方案**：
1. 统一软删除策略，对所有业务表添加 `deleted_at` 字段
2. 使用 GORM 的软删除特性
3. 或者明确区分"逻辑删除"和"物理删除"的场景

---

### 2.6 冗余字段

#### 问题1：`t_user` 的 `LoginFailureCount` 和 `LockedUntil` 字段

**证据**：模型中定义了这两个字段，但搜索代码发现没有实际使用的逻辑（没有登录失败计数和账户锁定功能）。

```go
type tUser struct {
    LoginFailureCount uint       `gorm:"column:login_failure_count"`
    LockedUntil       *time.Time `gorm:"column:locked_until"`
}
```

**建议方案**：
1. 如果计划实现登录锁定功能，保留并完善逻辑
2. 如果不需要，删除这两个字段

---

#### 问题2：`t_user` 的 `Avatar` 和 `Nickname` 字段

**证据**：User 领域模型中有 `Avatar` 和 `Nickname`，但数据库模型 `tUser` 中没有这些字段。

**影响**：
- 领域模型与数据库模型不一致
- 前端期望的字段在数据库中不存在

**建议方案**：
1. 如果需要头像和昵称，添加数据库字段
2. 如果不需要，从领域模型中移除

---

## 三、优化方案汇总

### 3.1 立即执行（高优先级）

| 优化项 | 操作 | 说明 |
|--------|------|------|
| 删除 `t_visitor_record` | DROP TABLE | 功能被 `t_access_log` 覆盖 |
| `t_article_content` 添加唯一约束 | ALTER TABLE | 防止重复内容 |
| `t_article_tag_rel` 添加索引 | ALTER TABLE | 优化标签查询 |
| `t_article_category_rel` 添加索引 | ALTER TABLE | 优化分类查询 |
| `t_article_topic_rel` 添加索引 | ALTER TABLE | 优化专题查询 |
| `t_statistics_article_pv` 添加索引 | ALTER TABLE | 优化 PV 统计 |
| `t_mp_user_favorite` 添加索引 | ALTER TABLE | 优化收藏查询 |

### 3.2 计划执行（中优先级）

| 优化项 | 操作 | 说明 |
|--------|------|------|
| 统一状态字段类型 | ALTER TABLE | 统一使用 `uint8` |
| 添加搜索历史清理机制 | 定时任务 | 清理 30 天前数据 |
| 修复 `t_user_role` 字段不一致 | ALTER TABLE 或修改代码 | 确保模型与数据库一致 |
| 统一软删除策略 | ALTER TABLE | 添加 `deleted_at` 字段 |

### 3.3 后续规划（低优先级）

| 优化项 | 操作 | 说明 |
|--------|------|------|
| IP 地址存储格式统一 | ALTER TABLE | `[]byte` → `VARCHAR(45)` |
| 完善角色管理功能 | 开发 | 添加角色 CRUD API |
| 登录失败锁定功能 | 开发 | 使用 `LoginFailureCount`/`LockedUntil` |
| 用户头像和昵称 | ALTER TABLE | 添加数据库字段 |

---

## 四、总结

### 4.1 问题统计

| 问题类型 | 数量 | 严重程度 |
|----------|------|----------|
| 未使用的表 | 1 | 高 |
| 缺少索引 | 6 | 高 |
| 缺少约束 | 1 | 高 |
| 类型不一致 | 1 | 中 |
| 软删除不统一 | 1 | 中 |
| 冗余字段 | 2 | 低 |
| 功能重叠 | 1 | 中 |

### 4.2 建议执行顺序

1. **第一阶段**：删除 `t_visitor_record`，添加所有缺失的索引和约束
2. **第二阶段**：统一状态字段类型，添加搜索历史清理机制
3. **第三阶段**：统一软删除策略，完善角色管理功能

### 4.3 风险评估

- **高风险**：删除 `t_visitor_record` 前需确认无历史数据需要迁移
- **中风险**：添加索引可能影响写入性能（建议在低峰期执行）
- **低风险**：字段类型调整需要同步更新前端代码