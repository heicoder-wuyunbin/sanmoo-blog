# Sanmoo Blog 实施任务清单

## 1. 文档定位

本清单不是给人工开发者自由发挥的待办，而是给 AI 编程代理直接执行的任务说明书。

使用方式：

- 由陛下审核本清单
- 审核通过后，将单个任务分配给对应电脑上的 AI 代理执行
- 严格按任务编号顺序推进
- 严格遵守“目录不交叉、职责不交叉、提交不交叉”

本清单以 [plan.md](file:///Users/wuyunbin/workspace/sanmoo-blog/plan.md) 为上位约束。

---

## 2. 全局执行规则

所有 AI 代理必须遵守以下规则：

### 2.1 产品与合规规则

- 项目产品定位必须收敛为“个人技术内容发布与知识整理平台”
- 必须遵守个人备案资质边界
- 不得新增或强化以下业务：
  - 评论社区
  - 用户投稿
  - 支付、订单、充值、会员
  - 社交关系链
  - 面向公众的大型用户运营机制
- 小程序相关用户数据只能服务于阅读体验、收藏、历史、订阅、轻量推荐
- 所有对外文案必须弱化“平台化”“社区化”“用户运营化”表达

### 2.2 协作规则

- 一个任务只能由一台电脑上的一个 AI 代理执行
- Legion 只允许修改后端、数据库、部署相关目录
- MacBook 只允许修改前端、小程序、README 相关目录
- 不允许两个 AI 代理同时修改同一个目录
- 如果任务依赖另一台电脑的输出，必须先读取对方已提交的文档或接口约定，再开始编码

### 2.3 开发规则

- 开始编码前必须先阅读任务指定输入文件
- 每个任务必须先产出最小实施计划，再开始修改代码
- 每个任务完成后必须执行与改动范围相匹配的检查
- 每个任务必须输出：
  - 改动文件列表
  - 完成内容摘要
  - 未完成项
  - 风险与后续建议

### 2.4 提交规则

- 每个任务单独提交
- 不允许把多个任务混在同一个提交中
- 提交信息必须包含任务编号，例如：`feat(L1): add filing-friendly compliance config`

---

## 3. 执行顺序总览

推荐顺序如下：

1. Legion 执行 `L0`、`L1`
2. MacBook 执行 `M0`
3. Legion 执行 `L2`、`L3`
4. MacBook 执行 `M1`、`M2`
5. Legion 执行 `L4`
6. MacBook 执行 `M3`、`M4`
7. Legion 执行 `L5`
8. MacBook 执行 `M5`

说明：

- `L` 代表 Legion 任务
- `M` 代表 MacBook 任务
- 先由 Legion 定边界和接口，再由 MacBook 接表现层和交互层

---

## 4. Legion 任务清单

## L0. 后端业务边界与合规约束落地

### 执行设备

Legion

### 任务目标

把 `plan.md` 中的业务边界和个人备案约束，落地成后端侧可执行的设计文档，作为后续后端改造的统一约束。

### 允许修改

- `sanmoo-server-go/**`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- 根目录 Docker 文件

### 必读输入

- `plan.md`
- `sanmoo-server-go/internal/interfaces/http/router/router.go`
- `sanmoo_blog_schema.sql`

### 实施要求

- 在 `sanmoo-server-go` 内新增后端侧业务边界文档
- 明确保留能力、冻结能力、禁止扩张能力
- 梳理 Web 端、后台端、小程序端三类接口边界
- 标记哪些接口属于“继续保留”，哪些属于“逐步弱化但暂不删除”

### 交付物

- 后端业务边界文档
- 后端接口域清单
- 后端冻结能力清单

### 验收标准

- 文档中明确写出个人备案约束
- 文档中明确写出小程序只做轻阅读分发
- 文档中明确写出重画像、重运营能力的冻结策略
- 不修改任何前端与小程序文件

---

## L1. 配置域重构设计与兼容方案

### 执行设备

Legion

### 任务目标

把现有混杂的配置域整理为“站点品牌、合规配置、渠道配置、基础设施配置”四类，并给出后端兼容落地方案。

### 允许修改

- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `DEPLOY.md`

### 必读输入

- `plan.md`
- `sanmoo_blog_schema.sql`
- `sanmoo-server-go/internal/application/setting/service.go`
- `sanmoo-server-go/internal/interfaces/http/handler/admin_setting_handler.go`
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/setting_repo.go`

### 实施要求

- 给出现有配置表字段归类表
- 设计重构后的配置域模型
- 优先考虑兼容式改造，不要一次性大拆大删
- 如需改表，先给出 SQL 变更方案，再落地代码
- 对外接口要保持阶段性兼容，避免前端立即失效

### 交付物

- 配置域映射文档
- 配置重构 SQL 方案
- 后端配置模型与接口兼容改造

### 验收标准

- 能清楚区分四类配置
- 代码中不再继续扩大 `UIConfig` 的职责
- 变更后不破坏现有基础设置读取能力
- 有明确的兼容说明

---

## L2. 小程序用户域降载与数据最小化方案

### 执行设备

Legion

### 任务目标

将小程序用户域从“重运营画像”降级为“轻阅读用户能力”，保留必要功能，弱化复杂运营资产。

### 允许修改

- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- Docker 与部署文档

### 必读输入

- `plan.md`
- `sanmoo_blog_schema.sql`
- `sanmoo-server-go/internal/interfaces/http/handler/mp_handler.go`
- `sanmoo-server-go/internal/application/mpuser/**`
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/mp_repo.go`
- `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/mp_user_admin_repo.go`

### 实施要求

- 明确保留：登录、收藏、历史、订阅、轻量推荐
- 明确弱化：复杂画像、重运营标签、雷达画像生成
- 在不引发前端直接崩溃的前提下，逐步降低相关接口的重要性
- 为后续 UI 隐藏和页面弱化提供接口契约说明
- 不要粗暴删除数据库表，优先采用“冻结、降权、减少暴露”的方式

### 交付物

- 小程序用户域保留/弱化矩阵
- 后端接口说明文档
- 兼容式代码调整

### 验收标准

- 小程序核心阅读功能不受影响
- 后端不再鼓励复杂画像型能力继续扩张
- 有可供前端读取的契约说明

---

## L3. 站长后台瘦身方案与权限收敛

### 执行设备

Legion

### 任务目标

将后台定位从“平台后台”收敛为“站长后台”，同时给出后端权限和运维能力的收敛方案。

### 允许修改

- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- Docker 与部署文档

### 必读输入

- `plan.md`
- `sanmoo-server-go/internal/interfaces/http/router/router.go`
- `sanmoo-server-go/internal/application/role/service.go`
- `sanmoo-server-go/internal/application/permission/service.go`
- `sanmoo-server-go/internal/application/dashboard/service.go`

### 实施要求

- 梳理后台功能的“高频保留项”和“低频冻结项”
- 权限模型收敛到适合个人站点长期维护的规模
- 不要求一次删除所有能力，但必须给出保留/冻结策略
- 后端侧先保证权限边界清晰，再由前端隐藏低优先级入口

### 交付物

- 后台功能保留矩阵
- 权限收敛方案
- 低频后台能力冻结说明

### 验收标准

- 内容管理相关能力优先级最高
- 平台化运维能力不再继续扩张
- 权限模型有清晰收敛方向

---

## L4. 合规配置与个人备案友好接口落地

### 执行设备

Legion

### 任务目标

把个人备案友好的站点信息、隐私、用户删除说明等能力落实到后端配置与接口中。

### 允许修改

- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`
- Docker 与部署文档

### 必读输入

- `plan.md`
- `sanmoo-server-go/internal/application/setting/service.go`
- `sanmoo-server-go/internal/interfaces/http/handler/web_handler.go`
- `sanmoo-server-go/internal/interfaces/http/handler/mp_handler.go`

### 实施要求

- 支持站点展示个人备案友好的合规信息
- 补齐隐私政策、联系方式、数据删除说明等基础配置支持
- 明确哪些信息是 Web 可见，哪些信息是小程序可见
- 输出给前端的字段命名要稳定、可解释

### 交付物

- 新增或扩展的配置字段
- 对外接口字段说明
- 相应后端逻辑实现

### 验收标准

- Web 和小程序都能读取必要合规信息
- 用户删除路径和说明清晰
- 没有引入平台化、商业化字段

---

## L5. 部署与数据保留策略收口

### 执行设备

Legion

### 任务目标

整理部署文档和运行策略，让项目更适合个人站点长期维护，并补齐日志保留与清理策略。

### 允许修改

- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `DEPLOY.md`
- `sanmoo-server-go/**`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`

### 必读输入

- `plan.md`
- `DEPLOY.md`
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `sanmoo-server-go/internal/application/maintenance/**`

### 实施要求

- 明确日志清理与数据保留策略
- 明确哪些容器与能力是个人站点长期必需的
- 优化部署说明，避免把项目描述成通用平台
- 若增加维护脚本或配置，必须与现有部署方式兼容

### 交付物

- 更新后的部署文档
- 日志与数据保留策略说明
- 必要的维护逻辑调整

### 验收标准

- 文档表达符合个人备案场景
- 数据治理策略清晰
- 不影响现有本地开发和 Docker 基础使用方式

---

## 5. MacBook 任务清单

## M0. 前端信息架构与文案基线设计

### 执行设备

MacBook

### 任务目标

把前端与小程序侧的产品表达统一收敛为“个人原创内容站 + 轻量阅读分发端”。

### 允许修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`

### 禁止修改

- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `docker-compose.local.yaml`
- `DEPLOY.md`

### 必读输入

- `plan.md`
- `README.md`
- `sanmoo-vite/src/App.tsx`
- `sanmoo-mp/miniprogram/pages/**`

### 实施要求

- 先产出前端侧信息架构说明文档
- 统一 Web、后台、小程序的产品语义
- 明确哪些页面文案需要降平台化表达
- 明确哪些入口需要弱化或隐藏

### 交付物

- Web 信息架构说明
- 小程序信息架构说明
- README 改版提纲

### 验收标准

- 文案统一强调个人原创内容站定位
- 不出现平台化、社区化扩张方向
- 不修改任何后端、数据库、部署文件

---

## M1. Web 站点对外表达重构

### 执行设备

MacBook

### 任务目标

重构 Web 前台的对外表达，使其更符合个人备案友好型内容站定位。

### 允许修改

- `sanmoo-vite/**`

### 禁止修改

- `sanmoo-server-go/**`
- `sanmoo-mp/**`
- `README.md`
- 所有根目录部署与数据库文件

### 必读输入

- `plan.md`
- `sanmoo-vite/src/pages/web/**`
- `sanmoo-vite/src/pages/web/components/**`

### 实施要求

- 调整首页、关于页、页脚、隐私页等关键页面文案和信息层级
- 明确站点是个人原创内容站
- 为备案信息、联系方式、隐私政策入口预留或完善展示位
- 不新增与评论、社区、交易相关的入口

### 交付物

- Web 前台页面改造
- 文案收敛结果

### 验收标准

- 首页、关于页、页脚表达统一
- 站点对外定位清晰
- 页面结构不再暗示平台化运营

---

## M2. 后台信息架构与菜单收敛

### 执行设备

MacBook

### 任务目标

把后台前端从“平台后台视觉感知”调整为“站长后台”。

### 允许修改

- `sanmoo-vite/**`

### 禁止修改

- `sanmoo-server-go/**`
- `sanmoo-mp/**`
- `README.md`
- 所有根目录部署与数据库文件

### 必读输入

- `plan.md`
- `sanmoo-vite/src/pages/Admin.tsx`
- `sanmoo-vite/src/pages/admin/**`

### 实施要求

- 调整后台导航层级与命名
- 强化内容管理入口
- 弱化低频平台型能力入口
- 设置中心要向“站点品牌 / 合规 / 渠道 / 基础设施”靠拢
- 若后端尚未完全改造完成，前端先做界面层整理与兼容占位

### 交付物

- 后台菜单调整
- 设置页结构调整
- 低优先级入口弱化方案

### 验收标准

- 后台主导航突出内容管理
- 设置页结构更清晰
- 不破坏已有基础操作流程

---

## M3. 小程序轻阅读模式改造

### 执行设备

MacBook

### 任务目标

把小程序体验收敛为轻量阅读分发端，保留阅读、收藏、历史、订阅，弱化重运营痕迹。

### 允许修改

- `sanmoo-mp/**`

### 禁止修改

- `sanmoo-vite/**`
- `sanmoo-server-go/**`
- `README.md`
- 所有根目录部署与数据库文件

### 必读输入

- `plan.md`
- `sanmoo-mp/miniprogram/pages/**`
- `sanmoo-mp/miniprogram/api/**`

### 实施要求

- 强化文章阅读、专题浏览、收藏、历史、订阅体验
- 弱化画像、标签运营、复杂推荐运营感知
- 页面与按钮命名要贴近阅读产品，而非运营平台
- 若后端仍保留兼容接口，前端可以先隐藏低优先级能力入口

### 交付物

- 小程序页面改造
- 小程序交互收敛结果

### 验收标准

- 小程序主路径围绕阅读消费
- 无明显平台化运营 UI 痕迹
- 轻量推荐可以保留，但不可喧宾夺主

---

## M4. README 产品定位与使用说明重写

### 执行设备

MacBook

### 任务目标

把 `README.md` 从“泛系统介绍”重写为“个人技术内容平台”的项目说明。

### 允许修改

- `README.md`

### 禁止修改

- `sanmoo-server-go/**`
- `sanmoo-vite/**`
- `sanmoo-mp/**`
- 所有根目录部署与数据库文件

### 必读输入

- `plan.md`
- 当前 `README.md`

### 实施要求

- 强调个人原创内容站定位
- 说明 Web 与小程序双端分发架构
- 弱化平台化后台叙述
- 明确个人备案友好的业务边界

### 交付物

- 更新后的 `README.md`

### 验收标准

- README 首屏即可看出项目定位
- 项目描述与 `plan.md` 一致
- 不出现社区、交易、会员等误导性表述

---

## M5. 前端契约对齐与收口

### 执行设备

MacBook

### 任务目标

在 Legion 完成后端配置与接口契约调整后，完成 Web 与小程序对新契约的适配收口。

### 允许修改

- `sanmoo-vite/**`
- `sanmoo-mp/**`
- `README.md`

### 禁止修改

- `sanmoo-server-go/**`
- `sanmoo_blog_schema.sql`
- 所有根目录部署与数据库文件

### 必读输入

- Legion 输出的接口契约文档
- `sanmoo-vite/src/services/**`
- `sanmoo-mp/miniprogram/api/**`

### 实施要求

- 对齐新增或调整后的配置字段
- 对齐合规信息展示
- 对齐小程序轻量化能力边界
- 清理旧文案、旧入口、旧展示逻辑

### 交付物

- Web API 适配
- 小程序 API 适配
- 最终 README 收口

### 验收标准

- 前后端契约一致
- 页面无失效字段和明显兼容问题
- 文案、入口、信息架构与目标定位统一

---

## 6. 任务分发模板

给 AI 代理下发任务时，建议使用下面模板：

```md
你现在执行 Sanmoo Blog 实施任务清单中的 `{任务编号}`。

执行设备：`{Legion 或 MacBook}`

必须遵守：
- 先阅读 `plan.md`
- 只允许修改任务指定目录
- 严禁修改任务禁止触碰的目录
- 不能新增与个人备案资质冲突的业务
- 完成后输出：
  - 改动文件列表
  - 实施结果
  - 验收结果
  - 风险与后续建议

开始前先给出你的最小实施计划，再开始执行。
```

---

## 7. 陛下审核重点

陛下在审核本清单时，建议重点看以下几点：

- 是否还存在目录交叉
- 是否有任何任务会诱导 AI 扩张平台型业务
- 是否每个任务都有清晰输入、输出、验收标准
- 是否每个任务都能单独提交、单独回滚
- 是否先后依赖关系清晰

如果以上五点都满足，这份清单就适合直接发给 AI 逐项执行。
