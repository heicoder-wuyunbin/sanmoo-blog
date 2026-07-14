# P1 阶段收尾计划

## 当前状态评估

### ✅ 已完成工作

1. **配置域重构**
   - 新配置表已设计并创建（brand/compliance/channel/infrastructure）
   - 数据迁移脚本已编写（20260709_create_new_config_tables.sql, 20260709_migrate_config_data.sql）
   - 后端代码已迁移到新表读写
   - 前端页面已按四类配置重组

2. **后台信息架构**
   - 导航菜单已按四类配置组织
   - 权限模型已精简（冻结用户/角色/权限管理）
   - 仪表盘聚焦内容表现

3. **API 层**
   - 新的配置 API 端点已实现
   - 前端已适配新 API

### ⚠️ 待完成工作

1. **数据库迁移未执行**
   - 新表已创建但数据未迁移
   - 旧表仍存在且被代码引用作为兼容回退
   - schema.sql 仍包含旧表定义

2. **代码清理未完成**
   - 后端仍有旧表兼容逻辑
   - 需要移除对旧表的依赖

3. **文档未更新**
   - config-domain-mapping.md 未标记 L3 完成
   - 缺少迁移执行指南

## 收尾任务清单

### 任务 1：执行数据库迁移

**目标**：将旧配置表数据迁移到新表

**步骤**：
1. 备份当前数据库
2. 执行迁移脚本：
   ```bash
   mysql -u root -p sanmoo_blog < sanmoo-server-go/migrations/20260709_create_new_config_tables.sql
   mysql -u root -p sanmoo_blog < sanmoo-server-go/migrations/20260709_migrate_config_data.sql
   ```
3. 验证迁移结果：
   ```sql
   SELECT * FROM t_blog_brand_config;
   SELECT * FROM t_blog_compliance_config;
   SELECT * FROM t_blog_channel_config;
   SELECT * FROM t_blog_infrastructure_config;
   ```

**验收标准**：
- 新表数据完整
- 前端配置页面功能正常
- 后端 API 返回正确数据

### 任务 2：清理旧表引用

**目标**：移除代码中对旧配置表的引用

**涉及文件**：
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/setting_repo.go`

**修改内容**：
1. 移除 `Get()` 方法中对旧表的 fallback 逻辑
2. 移除 `GetPrivacyConfig()` 中对 `t_blog_privacy_config` 的 fallback
3. 确保所有读写都指向新表

**验收标准**：
- 代码中无旧表引用
- 功能测试通过

### 任务 3：删除旧配置表

**目标**：清理数据库中的旧配置表

**步骤**：
1. 确认任务 1、2 已完成且功能正常
2. 创建删除旧表的迁移脚本：
   ```sql
   DROP TABLE IF EXISTS t_blog_core_config;
   DROP TABLE IF EXISTS t_blog_ui_config;
   DROP TABLE IF EXISTS t_blog_privacy_config;
   DROP TABLE IF EXISTS t_blog_social_config;
   DROP TABLE IF EXISTS t_blog_search_config;
   DROP TABLE IF EXISTS t_blog_storage_config;
   DROP TABLE IF EXISTS t_blog_email_config;
   ```
3. 执行删除
4. 更新 `sanmoo_blog_schema.sql`，移除旧表定义

**验收标准**：
- 旧表已删除
- schema.sql 只包含新表
- 系统功能正常

### 任务 4：更新文档

**目标**：更新配置域映射文档，标记 P1 完成

**涉及文件**：
- `documents/config-domain-mapping.md`

**修改内容**：
1. 在文档顶部添加状态标记：
   ```markdown
   **状态**：✅ P1 已完成（2026-07-15）
   - L1 新表创建：已完成
   - L2 数据迁移：已完成
   - L3 旧表清理：已完成
   ```
2. 更新"旧表保留策略"章节，标记旧表已删除
3. 添加迁移执行记录

### 任务 5：功能回归测试

**目标**：确保所有配置功能正常

**测试清单**：
- [ ] 站点品牌配置读写
- [ ] 合规配置读写
- [ ] 渠道配置读写
- [ ] 搜索配置读写
- [ ] 存储配置读写
- [ ] 邮件配置读写
- [ ] 前端配置页面展示正常
- [ ] 后端 API 响应正常

## 执行顺序

1. **任务 1**：执行数据库迁移（必须先做）
2. **任务 5**：功能回归测试（验证迁移成功）
3. **任务 2**：清理旧表引用（确认功能正常后）
4. **任务 5**：再次功能回归测试（验证代码清理）
5. **任务 3**：删除旧配置表（最后执行）
6. **任务 4**：更新文档（收尾）

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 数据迁移失败 | 高 | 执行前备份数据库 |
| 旧表删除后功能异常 | 高 | 先清理代码引用，再删除表 |
| 前端缓存导致显示异常 | 低 | 清理浏览器缓存和 Redis 缓存 |

## 时间估算

- 任务 1：10 分钟
- 任务 2：15 分钟
- 任务 3：10 分钟
- 任务 4：10 分钟
- 任务 5：20 分钟（两次测试）

**总计**：约 1 小时

## P1 完成标准

- [ ] 新配置表数据完整
- [ ] 旧配置表已删除
- [ ] 代码中无旧表引用
- [ ] 所有配置功能测试通过
- [ ] 文档已更新
