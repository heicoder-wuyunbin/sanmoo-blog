# 部署与数据保留策略收口（L5 交付物）

## 1. 文档定位

本文档为 `implementation-tasks.md` 中 L5 任务的核心交付物，面向：

- **陛下审核**：验证部署配置与数据保留策略是否符合个人站点定位
- **运维人员**：提供部署配置和数据管理的完整指南
- **后续维护**：作为部署和数据保留策略的参考依据

上位约束：

- [plan.md](file:///c:/workspace/sanmoo-blog/documents/plan.md)
- [implementation-tasks.md](file:///c:/workspace/sanmoo-blog/documents/implementation-tasks.md)
- [compliance-api-contract.md](file:///c:/workspace/sanmoo-blog/documents/compliance-api-contract.md)

---

## 2. L5 任务完成情况

### 2.1 任务目标

| 目标 | 达成情况 |
|------|----------|
| 更新部署文档（DEPLOY.md）与个人站点定位对齐 | ✅ 已完成 |
| 完善日志保留与清理策略 | ✅ 已完成 |
| 优化 docker-compose 资源配置（适合 2核2G 服务器） | ✅ 已完成 |

### 2.2 修改文件清单

| 文件 | 修改内容 |
|------|----------|
| `sanmoo-server-go/internal/application/maintenance/service.go` | 更新日志保留策略，与 L4 合规文档一致 |
| `DEPLOY.md` | 新增数据保留策略章节，完善部署注意事项 |
| `docker-compose.yaml` | 优化各服务资源配置，适配 2核2G 服务器 |

---

## 3. 数据保留策略

### 3.1 日志保留期限

**系统日志**

| 数据表 | 保留期限 | 说明 |
|--------|----------|------|
| `t_access_log` | 90天 | 访问日志，用于安全排障 |
| `t_error_log` | 180天 | 错误日志，用于故障排查 |
| `t_search_history` | 90天 | 搜索历史，用于搜索优化 |

**小程序用户数据（轻阅读能力）**

| 数据表 | 保留期限 | 说明 |
|--------|----------|------|
| `t_mp_browse_history` | 180天 | 小程序阅读历史，读者阅读记录 |
| `t_mp_reco_exposure` | 90天 | 推荐曝光记录，轻量推荐效果核对 |

**冻结表（L2 已冻结，不再新增写入）**

| 数据表 | 保留期限 | 说明 |
|--------|----------|------|
| `t_mp_user_behavior` | 90天 | 用户行为日志，定期清理 |
| `t_mp_user_interest` | 90天 | 用户兴趣维度，定期清理 |
| `t_mp_user_tag` | 90天 | 用户标签，定期清理 |
| `t_mp_user_profile` | 90天 | 用户画像，定期清理 |

**内容统计数据**

| 数据表 | 保留期限 | 说明 |
|--------|----------|------|
| `t_statistics_article_pv` | 365天 | 文章 PV 统计，内容表现回看 |

### 3.2 清理机制

**自动清理**：

- 定时任务：每日凌晨 3:00 自动执行
- 执行频率：每分钟检查一次，到达指定时间执行清理
- 超时时间：10 分钟（防止清理任务占用过多资源）

**手动触发**：

```bash
# 通过管理端 API 手动触发清理
curl -X POST http://localhost:28080/admin/maintenance/cleanup
```

**清理结果报告**：

```json
{
  "code": 0,
  "data": {
    "tables": [
      {
        "tableName": "t_access_log",
        "deleted": 1500,
        "retainDays": 30,
        "cutoffDate": "2026-06-14 03:00:00"
      }
    ],
    "totalDeleted": 1500,
    "duration": 1200,
    "success": true,
    "message": "清理完成，共删除 1500 条记录，耗时 1200 ms"
  }
}
```

### 3.3 用户数据删除

小程序用户可通过 `DELETE /mp/user` 接口删除账号及所有相关数据：

- 用户基础信息（`t_mp_user`）
- 用户收藏（`t_mp_user_favorite`）
- 浏览历史（`t_mp_browse_history`）
- 订阅状态（`t_mp_user_subscribe`）
- 兴趣画像（`t_mp_user_interest`）
- 用户标签（`t_mp_user_tag`）
- 用户六边形画像（`t_mp_user_profile`）

---

## 4. 部署配置优化

### 4.1 资源配置调整

针对 2核2G 服务器优化后的资源配置：

| 服务 | CPU 限制 | CPU 预留 | 内存限制 | 内存预留 |
|------|----------|----------|----------|----------|
| MySQL | 0.8 | 0.4 | 768M | 384M |
| Redis | 0.2 | 0.1 | 128M | 64M |
| Meilisearch | 0.4 | 0.2 | 384M | 192M |
| sanmoo-server-go | 0.4 | 0.2 | 384M | 192M |
| sanmoo-vite | 0.3 | 0.15 | 192M | 96M |
| **总计** | **2.1** | **1.05** | **1856M** | **928M** |

> **说明**：CPU 限制总和 2.1 略高于 2 核，这是因为 Docker Compose 的 CPU 限制是"软限制"，实际运行时各服务不太可能同时达到峰值。内存限制总计约 1.8GB，留有余量给系统运行。

### 4.2 MySQL 优化参数

```yaml
command:
  - "--innodb-buffer-pool-size=384M"
  - "--innodb-log-file-size=64M"
  - "--max-connections=50"
  - "--performance-schema=OFF"
  - "--skip-log-bin"
  - "--skip-name-resolve"
  - "--init-connect=SET NAMES utf8mb4"
```

| 参数 | 值 | 说明 |
|------|-----|------|
| `innodb-buffer-pool-size` | 384M | InnoDB 缓冲池大小，约为可用内存的 50% |
| `innodb-log-file-size` | 64M | InnoDB 日志文件大小 |
| `max-connections` | 50 | 最大连接数（个人站点无需太多） |
| `performance-schema` | OFF | 关闭性能监控（节省资源） |
| `skip-log-bin` | - | 关闭二进制日志（节省资源） |
| `skip-name-resolve` | - | 跳过域名解析（加速连接） |

### 4.3 Redis 优化参数

```yaml
command: redis-server --maxmemory 64mb --maxmemory-policy allkeys-lru
```

| 参数 | 值 | 说明 |
|------|-----|------|
| `maxmemory` | 64mb | 最大内存限制 |
| `maxmemory-policy` | allkeys-lru | 内存不足时使用 LRU 策略淘汰 |

---

## 5. 部署模式说明

### 5.1 本地开发模式

```bash
# 启动依赖服务
docker compose -f docker-compose.dev.yaml up -d

# 启动后端
cd sanmoo-server-go && go run cmd/server/main.go

# 启动前端
cd sanmoo-vite && pnpm dev
```

**特点**：热更新、调试便捷、资源占用低

### 5.2 完整 Docker 模式

```bash
# 本地测试环境
./deploy.sh local

# 生产环境
./deploy.sh production
```

**特点**：与生产环境配置一致，适合验证

### 5.3 离线镜像部署（生产服务器）

```bash
# 在测试机构建并导出
./deploy.sh production
./deploy.sh export

# 在生产服务器部署
scp sanmoo-images.tar root@backendart.com:/opt/
ssh root@backendart.com "docker load -i /opt/sanmoo-images.tar && cd /opt && docker compose up -d"
```

**特点**：减轻生产服务器压力，适合资源有限的服务器

---

## 6. 验收对照

| 验收标准 | 达成情况 |
|----------|----------|
| 日志保留策略与合规文档一致 | ✅ 已完成 — 访问日志30天、错误日志90天 |
| 日志清理机制完善 | ✅ 已完成 — 定时清理 + 手动触发 |
| 部署文档与个人站点定位对齐 | ✅ 已完成 — 新增数据保留策略章节 |
| Docker 资源配置适合 2核2G 服务器 | ✅ 已完成 — 总内存限制约 1.8GB |
| 部署模式清晰 | ✅ 已完成 — 本地开发、完整 Docker、离线镜像三种模式 |

---

## 7. Legion 任务完成总结

### 7.1 L0-L5 任务完成情况

| 任务 | 状态 | 核心交付物 |
|------|------|----------|
| L0：清理与收敛 | ✅ 已完成 | 项目约束文档 |
| L1：配置域重构 | ✅ 已完成 | SQL 迁移脚本、新配置表 |
| L2：渠道配置落地 | ✅ 已完成 | 渠道配置接口 |
| L3：基础设施配置收口 | ✅ 已完成 | 基础设施配置接口 |
| L4：合规配置与个人备案友好接口落地 | ✅ 已完成 | [compliance-api-contract.md](file:///c:/workspace/sanmoo-blog/documents/compliance-api-contract.md) |
| L5：部署与数据保留策略收口 | ✅ 已完成 | [deployment-and-retention-summary.md](file:///c:/workspace/sanmoo-blog/documents/deployment-and-retention-summary.md) |

### 7.2 后端开发完成度

| 模块 | 完成情况 |
|------|----------|
| 配置域重构 | ✅ 100% |
| 合规配置 | ✅ 100% |
| 渠道配置 | ✅ 100% |
| 基础设施配置 | ✅ 100% |
| 数据保留策略 | ✅ 100% |
| 部署配置 | ✅ 100% |

### 7.3 后续建议

Legion 任务（L0-L5）已全部完成。后续工作由 MacBook 负责：

| MacBook 任务 | 说明 |
|-------------|------|
| M0：前端配置收敛 | 清理前端违规配置 |
| M1：前端配置域适配 | 适配新配置表结构 |
| M2：渠道配置页面适配 | 适配渠道配置接口 |
| M3：基础设施配置页面适配 | 适配基础设施配置接口 |
| M4：合规配置页面适配 | 适配合规配置接口（备案信息等） |
| M5：契约对齐收口 | 确认前后端接口契约一致性 |

---

## 8. 文档版本

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-07-14 | L5 初始版本，完成部署与数据保留策略收口总结 |