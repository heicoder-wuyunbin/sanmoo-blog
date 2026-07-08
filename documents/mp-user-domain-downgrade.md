# 小程序用户域降级方案（L2 交付物）

## 1. 文档定位

本文档为 `implementation-tasks.md` 中 L2 任务的核心交付物，面向：

- **后端维护者**：明确哪些能力已冻结、冻结方式与代码标记位置
- **前端（MacBook）开发者**：提供稳定的接口契约说明，指导 M3/M5 阶段隐藏入口与页面弱化
- **陛下审核**：验证降级策略是否符合"轻阅读用户能力"定位与个人备案边界

上位约束：

- [plan.md](file:///c:/workspace/sanmoo-blog/documents/plan.md)
- [business-boundary.md](file:///c:/workspace/sanmoo-blog/documents/business-boundary.md)
- [frozen-capabilities.md](file:///c:/workspace/sanmoo-blog/documents/frozen-capabilities.md)

---

## 2. 降级原则

| 原则 | 说明 |
|------|------|
| 不粗暴删除 | 保留接口签名与数据表，避免前端直接崩溃 |
| 冻结计算 | 重运营画像的计算逻辑在 service 层短路，返回空结构 |
| 保留阅读 | 登录、收藏、历史、订阅、轻量推荐全部保留 |
| 减少暴露 | 后续由前端隐藏管理端入口，后端不再主动触发生成任务 |
| 标记清晰 | 所有冻结点在代码注释中以 `FROZEN (L2):` 标记 |

---

## 3. 保留 / 弱化 / 冻结矩阵

### 3.1 小程序端接口（/mp）— 全部保留

小程序端面向读者的核心阅读能力**全部保留**，不做任何降级。

| 接口 | 方法 | 能力分类 | 策略 |
|------|------|----------|------|
| `/mp/auth/session` | POST | 登录 | 保留 |
| `/mp/settings` | GET | 配置 | 保留 |
| `/mp/categories` | GET | 内容浏览 | 保留 |
| `/mp/tags` | GET | 内容浏览 | 保留 |
| `/mp/topics` | GET | 内容浏览 | 保留 |
| `/mp/topics/:id` | GET | 内容浏览 | 保留 |
| `/mp/topics/:id/articles` | GET | 内容浏览 | 保留 |
| `/mp/articles` | GET | 内容浏览 | 保留 |
| `/mp/articles/:id` | GET | 内容浏览 | 保留 |
| `/mp/categories/:id/articles` | GET | 内容浏览 | 保留 |
| `/mp/tags/:id/articles` | GET | 内容浏览 | 保留 |
| `/mp/archives` | GET | 内容浏览 | 保留 |
| `/mp/search/hot` | GET | 内容浏览 | 保留 |
| `/mp/user/profile` | GET | 用户基础 | 保留 |
| `/mp/user/profile` | POST | 用户基础 | 保留 |
| `/mp/favorites/:articleId` | POST | 收藏 | 保留 |
| `/mp/favorites/:articleId` | DELETE | 收藏 | 保留 |
| `/mp/favorites/:articleId/status` | GET | 收藏 | 保留 |
| `/mp/favorites` | GET | 收藏 | 保留 |
| `/mp/history/:articleId` | POST | 历史 | 保留 |
| `/mp/history` | DELETE | 历史 | 保留 |
| `/mp/history` | GET | 历史 | 保留 |
| `/mp/subscribe` | POST | 订阅 | 保留 |
| `/mp/subscribe/status` | GET | 订阅 | 保留 |
| `/mp/user` | DELETE | 账号注销 | 保留 |
| `/mp/privacy-policy` | GET | 合规 | 保留 |
| `/mp/recommendations` | GET | 轻量推荐 | 保留（仅规则推荐） |
| `/mp/behavior` | POST | 行为上报 | 保留（仅用于内容优化，不用于画像生成） |

### 3.2 管理端接口（/admin/mp-users）— 分级冻结

管理端的小程序用户管理接口按"重运营画像"程度分级处理。

| 接口 | 方法 | 能力分类 | L2 策略 | 代码处理 |
|------|------|----------|---------|----------|
| `/admin/mp-users` | GET | 用户列表 | 冻结（只读保留） | 保持原逻辑，前端隐藏入口 |
| `/admin/mp-users/:openid` | GET | 用户详情 | 冻结（只读保留） | 保持原逻辑，前端隐藏入口 |
| `/admin/mp-users/:openid/profile` | GET | 画像查看 | 冻结（只读保留） | 保持原逻辑，前端隐藏入口 |
| `/admin/mp-users/:openid/profile` | POST | 生成画像 | **冻结+短路** | 返回空画像结构，不再计算 |
| `/admin/mp-users/:openid/tags/generate` | POST | 生成标签 | **冻结+短路** | 返回空标签列表，不再计算 |
| `/admin/mp-users/:openid/tags` | GET | 标签查看 | 冻结（只读保留） | 保持原逻辑，前端隐藏入口 |
| `/admin/mp-users/:openid/tags/:tagId` | DELETE | 删除标签 | 冻结（保留） | 保持原逻辑，前端隐藏入口 |
| `/admin/mp-users/:openid/radar/refresh` | POST | 刷新雷达 | **冻结+短路** | 返回空雷达结构，不再计算 |

**策略说明**：

- **冻结（只读保留）**：接口仍可调用，返回历史已生成的数据，但不再主动触发新的计算。前端应隐藏对应入口。
- **冻结+短路**：接口签名保留以避免前端崩溃，但 service 层已短路实际计算逻辑，直接返回空结构，不再读写数据库。

---

## 4. 代码层冻结说明

### 4.1 已冻结的 Service 方法

以下三个方法在 `sanmoo-server-go/internal/application/mpuser/service.go` 中已冻结：

| 方法 | 冻结前行为 | 冻结后行为 |
|------|-----------|-----------|
| `GenerateUserProfile` | 调用 `repo.ComputeAndSaveProfile` 计算六维度画像并写入 `t_mp_user_profile` | 直接返回空 `UserProfile`（`Dimensions: []`），不读写数据库 |
| `GenerateUserTags` | 调用 `repo.ComputeAndSaveTags` 生成行为/兴趣标签并写入 `t_mp_user_tag` | 直接返回空 `[]UserTag`，不读写数据库 |
| `RefreshRadar` | 调用 `repo.ComputeAndSaveRadar` 聚合标签+兴趣+画像并写入多表 | 直接返回空 `RadarData`，不读写数据库 |

### 4.2 代码标记位置

所有冻结点均以 `FROZEN (L2):` 注释标记，可在以下文件中检索：

| 文件 | 标记内容 |
|------|----------|
| `sanmoo-server-go/internal/interfaces/http/handler/mp_user_admin_handler.go` | 三个生成类 handler 的文档注释 |
| `sanmoo-server-go/internal/application/mpuser/service.go` | 三个 service 方法的文档注释与短路实现 |

### 4.3 保留的 Repository 方法

以下 repository 方法**保留但不再被 service 层主动调用**，仅供未来可能的只读查询或数据迁移使用：

- `ComputeAndSaveProfile`
- `ComputeAndSaveTags`
- `ComputeAndSaveRadar`

这些方法仍存在于 `mp_user_admin_repo.go` 和 `repository.go` 接口中，未做删除，符合"不粗暴删除"原则。后续 L3/L5 阶段可评估是否移除。

---

## 5. 数据表冻结策略

遵循"不粗暴删除数据库表"原则，以下数据表保留但停止主动写入。

| 数据表 | 冻结前用途 | L2 冻结策略 | 保留期限 |
|--------|-----------|------------|----------|
| `t_mp_user` | 小程序用户基础信息 | **保留读写**（登录、收藏、历史仍需使用） | 长期 |
| `t_mp_user_profile` | 六边形画像维度得分 | 停止写入，保留只读查询 | 待 L5 评估 |
| `t_mp_user_tag` | 用户行为/兴趣标签 | 停止自动生成写入，保留只读查询与手动删除 | 待 L5 评估 |
| `t_mp_user_interest` | 用户兴趣维度 | 停止写入，保留只读查询 | 待 L5 评估 |
| `t_mp_user_behavior` | 用户行为日志 | **保留写入**（行为上报仍用于内容优化） | 长期 |
| `t_mp_reco_exposure` | 推荐曝光记录 | 保留基础记录，不做复杂分析 | 待 L5 评估 |

**说明**：

- `t_mp_user` 和 `t_mp_user_behavior` 仍需读写，因为登录、收藏、历史、轻量推荐依赖这些数据。
- 画像/标签/兴趣三张表停止主动写入，但保留历史数据供管理端只读查看（前端隐藏入口后实际不再访问）。
- 不执行任何 `DROP TABLE` 或 `DELETE` 操作。

---

## 6. 前端契约说明（提供给 MacBook）

### 6.1 小程序端（sanmoo-mp）契约

小程序端**无需任何接口适配**，所有 `/mp/` 接口保持原有请求与响应格式不变。

M3 阶段的改造重点：

- 强化阅读、收藏、历史、订阅体验
- 弱化或隐藏画像、标签运营、复杂推荐的 UI 痕迹
- 若小程序中存在"我的画像""我的标签"等页面，建议隐藏入口但保留页面路由（避免路由跳转失败）

### 6.2 管理端（sanmoo-vite）契约

管理端 `/admin/mp-users` 系列接口的**响应格式保持不变**，但三个生成类接口的返回值已变为空结构：

#### 6.2.1 生成画像接口

```
POST /admin/mp-users/:openid/profile
```

L2 冻结后响应：

```json
{
  "code": 0,
  "data": {
    "dimensions": [],
    "updatedAt": null
  }
}
```

前端处理建议：`dimensions` 为空数组时，画像区域显示"暂无画像数据"或直接隐藏画像模块。

#### 6.2.2 生成标签接口

```
POST /admin/mp-users/:openid/tags/generate
```

L2 冻结后响应：

```json
{
  "code": 0,
  "data": []
}
```

前端处理建议：返回空数组时，标签生成按钮可置灰或隐藏，标签列表区域显示"暂无标签"。

#### 6.2.3 刷新雷达接口

```
POST /admin/mp-users/:openid/radar/refresh
```

L2 冻结后响应：

```json
{
  "code": 0,
  "data": {
    "tags": [],
    "interests": [],
    "profile": {
      "dimensions": [],
      "updatedAt": null
    }
  }
}
```

前端处理建议：三个字段均为空时，雷达图区域显示"暂无雷达数据"或直接隐藏雷达图模块。

#### 6.2.4 只读接口

以下接口响应格式不变，仍返回历史数据（可能为空）：

- `GET /admin/mp-users` — 用户列表
- `GET /admin/mp-users/:openid` — 用户详情
- `GET /admin/mp-users/:openid/profile` — 画像查看
- `GET /admin/mp-users/:openid/tags` — 标签查看
- `DELETE /admin/mp-users/:openid/tags/:tagId` — 删除标签

### 6.3 M2/M5 阶段建议

| 阶段 | 建议 |
|------|------|
| M2（后台菜单收敛） | 完整隐藏"小程序用户管理"菜单入口 |
| M3（小程序轻阅读改造） | 隐藏画像/标签相关页面入口，保留阅读、收藏、历史、订阅 |
| M5（契约对齐收口） | 确认前端不再调用三个生成类接口后，后端可在 L3/L5 评估是否移除路由 |

---

## 7. 验收对照

| 验收标准 | 达成情况 |
|----------|----------|
| 小程序核心阅读功能不受影响 | 达成 — `/mp/` 下所有接口保持原逻辑，未做任何改动 |
| 后端不再鼓励复杂画像型能力继续扩张 | 达成 — 三个生成类方法已短路，不再计算与写入 |
| 有可供前端读取的契约说明 | 达成 — 本文档第 6 章提供完整前端契约 |
| 不粗暴删除数据库表 | 达成 — 未删除任何表，仅停止主动写入 |
| 代码中明确标记冻结点 | 达成 — `FROZEN (L2):` 标记已添加至 handler 与 service |

---

## 8. 风险与后续建议

### 8.1 当前风险

| 风险 | 等级 | 说明 |
|------|------|------|
| 前端仍调用生成接口 | 低 | 接口仍可调用但返回空数据，不会崩溃，仅无实际效果 |
| 历史画像数据残留 | 低 | `t_mp_user_profile` 等表仍有历史数据，管理端只读查看仍会展示 |
| Repository 方法未使用 | 低 | `ComputeAndSave*` 系列方法不再被调用，但不影响编译 |

### 8.2 后续建议

1. **L3 阶段**：评估是否在路由层移除三个生成类接口的注册，或返回 `410 Gone`
2. **L5 阶段**：评估是否清理 `t_mp_user_profile`、`t_mp_user_tag`、`t_mp_user_interest` 三张表的历史数据
3. **前端配合**：MacBook 在 M2 阶段隐藏管理端入口后，可显著降低这些接口的调用量
4. **监控**：建议在 L5 阶段确认前端已完全不再调用生成类接口后，再考虑代码层移除

---

## 9. 文档版本

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-07-09 | L2 初始版本，完成小程序用户域降级方案与前端契约说明 |
