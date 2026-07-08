# Sanmoo Blog 业务架构诊断与优化方案

> 2026-07-08 | 基于 sanmoo_blog_schema.sql 实际结构 | 个人备案

---

## 一、诊断结论（TL;DR）

**系统现状：** 36 张表，覆盖 CMS + RBAC + 小程序用户体系 + 推荐引擎 + 全链路日志，架构完整度较高。

**3 个必须立刻修的问题：**

1. `t_blog_ui_config` 与 `t_blog_social_config` / `t_blog_search_config` 字段大面积重复，存在数据不一致风险
2. `t_article_content.article_id` 无唯一约束，存在一篇文章多份内容的隐患
3. `t_mp_user_subscribe` 的 openid / subscribe 允许 NULL，唯一索引命名不规范

**3 个建议尽快做的事：**

1. 小程序端隐私政策需覆盖用户画像和行为追踪
2. 配置表版本号机制未落地，变更无审计
3. 日志表无归档策略，长期运行有存储膨胀风险

**不存在的问题：** 系统中没有评论表、没有留言表，不涉及电子公告服务合规风险。

---

## 二、数据库全景

### 2.1 完整表清单

```
业务域                    表数量    表名
─────────────────────────────────────────────────────────────
内容管理                    8       t_article, t_article_content,
                                    t_category, t_tag, t_topic,
                                    t_article_category_rel,
                                    t_article_tag_rel,
                                    t_article_topic_rel

后台用户与权限              5       t_user, t_role, t_permission,
                                    t_user_role, t_role_permission

小程序用户                  9       t_mp_user, t_mp_user_favorite,
                                    t_mp_browse_history,
                                    t_mp_user_subscribe,
                                    t_mp_user_behavior,
                                    t_mp_user_interest,
                                    t_mp_user_profile,
                                    t_mp_user_tag,
                                    t_mp_reco_exposure

系统配置                    7       t_blog_core_config,
                                    t_blog_social_config,
                                    t_blog_search_config,
                                    t_blog_privacy_config,
                                    t_blog_storage_config,
                                    t_blog_email_config,
                                    t_blog_ui_config ⚠️

日志与统计                  6       t_access_log, t_error_log,
                                    t_third_party_log,
                                    t_statistics_article_pv,
                                    t_visitor_record,
                                    t_search_history

外部链接                    1       t_link
─────────────────────────────────────────────────────────────
合计                       36
```

### 2.2 各表设计要点

**t_article（文章）**
- slug 字段做 SEO 友好 URL，有唯一约束
- publish_time 支持定时发布，is_published 控制发布状态
- is_top 置顶 + like_num 点赞 + share_num 分享
- 联合索引 `(is_top, is_published, create_time)` 覆盖首页列表查询

**t_article_content（文章内容）**
- 外键关联 t_article，CASCADE 删除
- ⚠️ **缺失 article_id 唯一约束**，可能出现一篇文章对应多条内容

**t_category / t_tag（分类/标签）**
- 均支持软删除（deleted_at）
- name 均有唯一约束

**t_topic（专题）**
- 支持 is_series 标识是否为系列专题
- status 字段控制启用/禁用
- 有 cover_image 封面图

**t_user（后台用户）**
- 标准用户名/密码哈希/邮箱登录
- login_failure_count + locked_until 实现登录失败锁定
- last_login_ip 记录登录 IP
- status 用字符串 ENABLED/DISABLED

**t_permission（权限）**
- perm_key 唯一，三级命名（module:resource:operation）
- type 区分 api / menu / button
- front_path + icon 支持前端菜单渲染
- 142 条权限记录（AUTO_INCREMENT=142）

**t_mp_user（小程序用户）**
- openid 唯一，含昵称、头像
- status 控制启用/禁用
- first_login_time + last_login_time

**t_mp_user_behavior（行为日志）**
- event_type 覆盖 view/click/stay/like/favorite/share
- 含 stay_seconds 停留时长、scene 场景、strategy 推荐策略
- 外键关联文章，CASCADE 删除

**t_mp_user_interest（兴趣画像）**
- dimension_type 维度：tag / category
- score 兴趣分 decimal(12,4)
- (openid, dimension_type, dimension_id) 唯一

**t_mp_user_profile（画像维度）**
- 六边形维度设计
- dimension + score(0-100)

**t_mp_user_tag（用户标签）**
- 来源 auto/manual，分类 behavior/preference/level
- 含 score 标签得分

**t_mp_reco_exposure（推荐曝光）**
- 含 strategy 推荐策略、position 曝光位次、clicked 是否点击
- request_id 关联一次推荐请求
- 支持 CTR 效果评估

**t_blog_*_config（配置表）**
- 6 张独立配置表 + 1 张 UI 配置表
- 单行表设计，CHECK 约束 id 固定为 1
- t_blog_email_config 使用 JSON 字段存储
- ⚠️ t_blog_ui_config 与 social/search 配置表字段重复

**t_access_log（访问日志）**
- 全链路追踪：trace_id、IP、响应时间、响应状态码
- request_source 区分来源（Chrome 浏览器、iPhone 微信等）
- is_error 标识 + error_id 关联错误日志

**t_link（友链）**
- is_active 控制启用/禁用
- url 唯一约束，防重复
- sort_order 排序

---

## 三、问题清单

### 3.1 数据一致性问题

| # | 问题 | 严重度 | 影响 |
|---|------|--------|------|
| 1 | t_blog_ui_config 与 t_blog_social_config 字段重复 | 🔴 高 | 数据不一致，维护混乱 |
| 2 | t_blog_ui_config 与 t_blog_search_config 字段重复 | 🔴 高 | 同上 |
| 3 | t_article_content 无 article_id 唯一约束 | 🔴 高 | 一篇文章可能多条内容 |

**问题 1/2 详情：**

`t_blog_ui_config` 包含了以下重复字段：
- 社交字段：github_home, csdn_home, gitee_home, zhihu_home, github_show 等 → 与 `t_blog_social_config` 完全重复
- 搜索字段：search_engine, meilisearch_host, meilisearch_api_key, meilisearch_index, hot_search_words, hot_search_mode, recommend_strategy → 与 `t_blog_search_config` 大部分重复

**建议方案：**
1. 排查代码中实际读写的是哪张表
2. 如 t_blog_ui_config 是历史遗留，废弃或清空其中重复字段
3. 统一使用 t_blog_social_config 和 t_blog_search_config 作为唯一数据源

### 3.2 设计规范问题

| # | 问题 | 严重度 | 详情 |
|---|------|--------|------|
| 4 | t_mp_user_subscribe 字段 NULL | 🟡 中 | openid、subscribe 应为 NOT NULL |
| 5 | t_mp_user_subscribe 索引命名 | 🟡 中 | idx_t_mp_user_subscribe_open_id 应改为 uk_openid |
| 6 | t_user.status 用字符串 | 🟡 中 | 'ENABLED'/'DISABLED'，其他表用 tinyint |
| 7 | t_blog_email_config 主键类型 | 🟢 低 | bigint，其他配置表用 tinyint |

### 3.3 运维风险

| # | 问题 | 严重度 | 详情 |
|---|------|--------|------|
| 8 | 日志表无归档策略 | 🟡 中 | access_log 已有 7607 条，持续增长 |
| 9 | 行为日志无清理策略 | 🟡 中 | behavior 643 条，持续增长 |
| 10 | config_version 未落地使用 | 🟢 低 | 多张配置表有 version 字段但未见审计 |

### 3.4 合规风险

| # | 问题 | 严重度 | 详情 |
|---|------|--------|------|
| 11 | 小程序用户画像缺乏隐私授权 | 🟡 中 | 收集行为+画像+标签，需明确告知 |
| 12 | t_blog_core_config 和 t_blog_privacy_config 都有 privacy_policy | 🟢 低 | 字段冗余，可能不一致 |

> 系统无评论表、无留言表，不涉及电子公告服务合规风险。

---

## 四、优化方案

### 4.1 第一阶段：修数据问题（本周）

**任务 1：清理 t_blog_ui_config 重复字段**

```sql
-- 方案：保留 t_blog_ui_config 结构但废弃其社交/搜索字段
-- 或直接 drop 该表（需确认代码中无引用）
-- 迁移脚本放在 migrations/ 目录
```

**任务 2：t_article_content 加唯一约束**

```sql
-- 先检查是否有重复数据
SELECT article_id, COUNT(*) FROM t_article_content GROUP BY article_id HAVING COUNT(*) > 1;

-- 无重复则加约束
ALTER TABLE t_article_content ADD UNIQUE KEY uk_article_id (article_id);
```

**任务 3：修复 t_mp_user_subscribe**

```sql
ALTER TABLE t_mp_user_subscribe 
  MODIFY openid varchar(128) NOT NULL COMMENT '微信 openid',
  MODIFY subscribe tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否订阅';

-- 重命名索引
ALTER TABLE t_mp_user_subscribe 
  DROP INDEX idx_t_mp_user_subscribe_open_id,
  ADD UNIQUE KEY uk_openid (openid);
```

### 4.2 第二阶段：补合规与运维（2 周内）

**任务 4：小程序隐私政策完善**
- 在隐私政策中逐项列明：openid、昵称、头像、浏览历史、收藏、行为日志、兴趣画像、用户标签
- 说明行为数据用于推荐优化
- 小程序首次进入弹窗同意

**任务 5：日志归档策略**
- 制定规则：access_log 保留 90 天，error_log 保留 180 天，behavior 保留 90 天
- 定时任务清理过期数据
- 或迁移到时序数据库

**任务 6：友链默认审核**
- 如果前台有友链提交入口，新友链默认 is_active=0
- 管理员手动审核后启用

### 4.3 第三阶段：功能增强（按需）

**任务 7：文章版本历史**
- t_article_content 增加 version 字段，或新表 t_article_content_version
- 编辑时自动保存旧版本

**任务 8：SEO 字段扩展**
- t_article 增加 seo_title、seo_keywords 字段
- t_category / t_tag / t_topic 增加 seo_description

**任务 9：Sitemap 自动生成**
- 后端定时生成 XML Sitemap
- 含文章、分类、标签、专题页

**任务 10：推荐效果看板**
- 基于 t_mp_reco_exposure 计算各策略 CTR
- 后台仪表盘展示推荐效果

---

## 五、架构评价

### 做得好的

| 设计点 | 说明 |
|--------|------|
| 推荐闭环 | 行为日志 → 兴趣画像 → 用户标签 → 推荐曝光 → 效果评估，链路完整 |
| 全链路追踪 | trace_id 贯穿 access_log → error_log，排查问题方便 |
| 账户安全 | 登录失败计数 + 锁定时间 + IP 记录，设计到位 |
| 单行配置表 | CHECK 约束确保单行，避免配置多行混乱 |
| 软删除 | category/tag 支持软删除，数据可恢复 |
| 权限三级分类 | api/menu/button + front_path/icon，前端菜单可动态渲染 |

### 需要改进的

| 问题 | 建议 |
|------|------|
| 7 张配置表偏多 | 长期可评估合并为 2-3 张 |
| UI 配置表与独立表重复 | 立即清理 |
| 无数据库迁移版本管理 | 引入 migration 版本号表 |
| 日志表无限增长 | 制定归档策略 |
| 行为数据隐私 | 完善授权和隐私政策 |

---

## 六、执行摘要

| 优先级 | 数量 | 核心内容 |
|--------|------|----------|
| P0 立即 | 3 | UI 配置清理、article_content 唯一约束、subscribe 修复 |
| P1 本周 | 3 | 隐私政策、日志归档、友链审核 |
| P2 按需 | 4 | 版本历史、SEO、Sitemap、推荐看板 |

全部 P0 项预计 1 天内可完成，P1 项预计 3-5 天。