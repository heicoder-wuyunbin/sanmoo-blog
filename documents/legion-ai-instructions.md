# Sanmoo Blog Legion 专用 AI 执行指令

## 1. 使用说明

本文件只给 `Legion` 电脑上的 AI 使用。

目标：

- 只处理后端、数据库、部署、合规基础能力
- 不碰前端、小程序、README
- 按顺序执行 `L0` -> `L1` -> `L2` -> `L3` -> `L4` -> `L5`

执行原则：

- 每次只执行一个任务
- 每个任务开始前，先阅读 `plan.md`、`implementation-tasks.md` 和本文件
- 每个任务完成后单独提交
- 若发现需要修改前端、小程序、README，立即停止并说明该工作应由 `MacBook` 处理

---

## 2. Legion 全局系统指令

将下面这段直接发给 Legion 上的 AI，作为所有任务共同遵守的执行约束：

```md
你现在是 Sanmoo Blog 项目的 Legion 执行代理。

你的职责边界：
- 只允许修改后端、数据库、部署、合规基础能力相关内容
- 严禁修改 `sanmoo-vite/**`
- 严禁修改 `sanmoo-mp/**`
- 严禁修改 `README.md`

你必须始终遵守以下业务约束：
- 项目定位必须收敛为“个人技术内容发布与知识整理平台”
- 必须符合个人备案资质边界
- 不得新增或强化评论、投稿、会员、支付、订单、社交关系链、公众运营平台能力
- 小程序数据只能服务于阅读体验、收藏、历史、订阅、轻量推荐
- 后端改造优先采用兼容式收敛，不做粗暴删除

你的工作方式：
- 开始前先阅读 `plan.md`、`implementation-tasks.md`、`legion-ai-instructions.md`
- 先给出最小实施计划，再开始改动
- 只修改当前任务允许的目录
- 每次完成后输出：
  - 改动文件列表
  - 实施结果
  - 验收结果
  - 风险与后续建议
- 每个任务单独提交，不混任务

如果你发现任务需要修改前端、小程序、README，请停止并明确指出这属于 MacBook 范围。
```

---

## 3. 执行顺序

Legion 必须按以下顺序执行：

1. `L0`
2. `L1`
3. `L2`
4. `L3`
5. `L4`
6. `L5`

只有当前任务完成并通过检查后，才能进入下一个任务。

---

## 4. 可直接投喂的任务指令

## L0 指令

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `L0`。

执行设备：`Legion`

任务目标：
- 把 `plan.md` 中的业务边界和个人备案约束，落地为后端侧可执行的设计文档
- 作为后续后端改造的统一约束

只允许修改：
- `sanmoo-server-go/**`

严禁修改：
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- 根目录 Docker 文件

开始前必须阅读：
- `plan.md`
- `implementation-tasks.md`
- `sanmoo-server-go/internal/interfaces/http/router/router.go`
- `sanmoo_blog_schema.sql`

实施要求：
- 在 `sanmoo-server-go` 内新增后端侧业务边界文档
- 明确保留能力、冻结能力、禁止扩张能力
- 梳理 Web 端、后台端、小程序端三类接口边界
- 标记哪些接口属于“继续保留”，哪些属于“逐步弱化但暂不删除”
- 明确个人备案约束
- 明确小程序只做轻阅读分发
- 明确重画像、重运营能力冻结策略

交付物：
- 后端业务边界文档
- 后端接口域清单
- 后端冻结能力清单

验收标准：
- 文档清楚、可供后续任务直接引用
- 不修改任何前端与小程序文件

开始前先给出最小实施计划，再执行。
完成后输出：
- 改动文件列表
- 实施结果
- 验收结果
- 风险与后续建议
```

---

## L1 指令

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `L1`。

执行设备：`Legion`

任务目标：
- 把现有混杂的配置域整理为“站点品牌、合规配置、渠道配置、基础设施配置”四类
- 给出后端兼容落地方案

只允许修改：
- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

严禁修改：
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `DEPLOY.md`

开始前必须阅读：
- `plan.md`
- `implementation-tasks.md`
- `sanmoo_blog_schema.sql`
- `sanmoo-server-go/internal/application/setting/service.go`
- `sanmoo-server-go/internal/interfaces/http/handler/admin_setting_handler.go`
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/setting_repo.go`
- `L0` 的输出文档

实施要求：
- 给出现有配置表字段归类表
- 设计重构后的配置域模型
- 优先采用兼容式改造，不要一次性大拆大删
- 如需改表，先给出 SQL 变更方案，再落地代码
- 对外接口要保持阶段性兼容，避免前端立即失效
- 代码中不要继续扩大 `UIConfig` 的职责

交付物：
- 配置域映射文档
- 配置重构 SQL 方案
- 后端配置模型与接口兼容改造

验收标准：
- 能清楚区分四类配置
- 不破坏现有基础设置读取能力
- 有明确兼容说明

开始前先给出最小实施计划，再执行。
完成后输出：
- 改动文件列表
- 实施结果
- 验收结果
- 风险与后续建议
```

---

## L2 指令

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `L2`。

执行设备：`Legion`

任务目标：
- 将小程序用户域从“重运营画像”降级为“轻阅读用户能力”
- 保留必要功能，弱化复杂运营资产

只允许修改：
- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

严禁修改：
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- Docker 与部署文档

开始前必须阅读：
- `plan.md`
- `implementation-tasks.md`
- `sanmoo_blog_schema.sql`
- `sanmoo-server-go/internal/interfaces/http/handler/mp_handler.go`
- `sanmoo-server-go/internal/application/mpuser/**`
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/mp_repo.go`
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/mp_user_admin_repo.go`
- `L0`、`L1` 的输出文档

实施要求：
- 明确保留：登录、收藏、历史、订阅、轻量推荐
- 明确弱化：复杂画像、重运营标签、雷达画像生成
- 在不引发前端直接崩溃的前提下，逐步降低相关接口的重要性
- 为后续 UI 隐藏和页面弱化提供接口契约说明
- 不要粗暴删除数据库表，优先采用“冻结、降权、减少暴露”的方式

交付物：
- 小程序用户域保留/弱化矩阵
- 后端接口说明文档
- 兼容式代码调整

验收标准：
- 小程序核心阅读功能不受影响
- 后端不再鼓励复杂画像型能力继续扩张
- 有可供前端读取的契约说明

开始前先给出最小实施计划，再执行。
完成后输出：
- 改动文件列表
- 实施结果
- 验收结果
- 风险与后续建议
```

---

## L3 指令

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `L3`。

执行设备：`Legion`

任务目标：
- 将后台定位从“平台后台”收敛为“站长后台”
- 给出后端权限和运维能力的收敛方案

只允许修改：
- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

严禁修改：
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- Docker 与部署文档

开始前必须阅读：
- `plan.md`
- `implementation-tasks.md`
- `sanmoo-server-go/internal/interfaces/http/router/router.go`
- `sanmoo-server-go/internal/application/role/service.go`
- `sanmoo-server-go/internal/application/permission/service.go`
- `sanmoo-server-go/internal/application/dashboard/service.go`
- `L0`、`L1`、`L2` 的输出文档

实施要求：
- 梳理后台功能的“高频保留项”和“低频冻结项”
- 权限模型收敛到适合个人站点长期维护的规模
- 不要求一次删除所有能力，但必须给出保留/冻结策略
- 后端侧先保证权限边界清晰，再由前端隐藏低优先级入口

交付物：
- 后台功能保留矩阵
- 权限收敛方案
- 低频后台能力冻结说明

验收标准：
- 内容管理相关能力优先级最高
- 平台化运维能力不再继续扩张
- 权限模型有清晰收敛方向

开始前先给出最小实施计划，再执行。
完成后输出：
- 改动文件列表
- 实施结果
- 验收结果
- 风险与后续建议
```

---

## L4 指令

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `L4`。

执行设备：`Legion`

任务目标：
- 把个人备案友好的站点信息、隐私、用户删除说明等能力落实到后端配置与接口中

只允许修改：
- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

严禁修改：
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- Docker 与部署文档

开始前必须阅读：
- `plan.md`
- `implementation-tasks.md`
- `sanmoo-server-go/internal/application/setting/service.go`
- `sanmoo-server-go/internal/interfaces/http/handler/web_handler.go`
- `sanmoo-server-go/internal/interfaces/http/handler/mp_handler.go`
- `L0`、`L1`、`L2`、`L3` 的输出文档

实施要求：
- 支持站点展示个人备案友好的合规信息
- 补齐隐私政策、联系方式、数据删除说明等基础配置支持
- 明确哪些信息是 Web 可见，哪些信息是小程序可见
- 输出给前端的字段命名要稳定、可解释
- 不引入平台化、商业化字段

交付物：
- 新增或扩展的配置字段
- 对外接口字段说明
- 相应后端逻辑实现

验收标准：
- Web 和小程序都能读取必要合规信息
- 用户删除路径和说明清晰
- 字段设计稳定

开始前先给出最小实施计划，再执行。
完成后输出：
- 改动文件列表
- 实施结果
- 验收结果
- 风险与后续建议
```

---

## L5 指令

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `L5`。

执行设备：`Legion`

任务目标：
- 整理部署文档和运行策略，让项目更适合个人站点长期维护
- 补齐日志保留与清理策略

只允许修改：
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `DEPLOY.md`
- `sanmoo-server-go/**`

严禁修改：
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`

开始前必须阅读：
- `plan.md`
- `implementation-tasks.md`
- `DEPLOY.md`
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `sanmoo-server-go/internal/application/maintenance/**`
- `L0` 到 `L4` 的输出文档

实施要求：
- 明确日志清理与数据保留策略
- 明确哪些容器与能力是个人站点长期必需的
- 优化部署说明，避免把项目描述成通用平台
- 若增加维护脚本或配置，必须与现有部署方式兼容

交付物：
- 更新后的部署文档
- 日志与数据保留策略说明
- 必要的维护逻辑调整

验收标准：
- 文档表达符合个人备案场景
- 数据治理策略清晰
- 不影响现有本地开发和 Docker 基础使用方式

开始前先给出最小实施计划，再执行。
完成后输出：
- 改动文件列表
- 实施结果
- 验收结果
- 风险与后续建议
```

---

## 5. Legion 完成定义

Legion 侧所有任务完成后，必须额外输出一份最终总结，至少包含：

- 新增或修改的后端文档列表
- 后端配置域重构结果
- 小程序用户域保留/冻结结论
- 后台瘦身和权限收敛结论
- 对 MacBook 的前端契约交接说明

只有在这份总结齐备后，MacBook 才进入最后的契约收口阶段。
