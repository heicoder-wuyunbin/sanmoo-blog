# Sanmoo Blog 优化与开发计划（双机并行 · 单日攻坚版）

> **项目背景**：个人备案资质博客系统（闽ICP备2026004727号-1）
> **作战单位**：Mac（主力） + Legion（助攻），双机并行
> **计划周期**：1 个工作日（每台 8h 工作量，合计约 16 人时）
> **核心原则**：符合个人备案合规、安全加固、SEO 提效、体验升级、代码质量
> **任务分配原则**：Mac 负责核心架构 + 前后端联动改造；Legion 负责独立模块 + 优化 + 质量工程

---

## 一、作战序列总览

| 优先级 | 任务 | 负责机器 | 预估工时 | 依赖 |
|--------|------|----------|----------|------|
| **P0** | 接口限流防刷中间件（Redis 滑动窗口） | Mac | 1.5h | 无 |
| **P0** | 文章 URL 伪静态化 + Slug 全链路 | Mac | 2.5h | 无 |
| **P0** | 文章定时发布 + 调度器 | Mac | 2h | 无 |
| **P0** | 访问日志自动清理 + 数据保留策略 | Legion | 1.5h | 无 |
| **P1** | 文章阅读体验全面升级（进度条/代码复制/灯箱） | Mac | 2h | 无 |
| **P1** | RBAC 菜单级权限细化 + 前端动态路由 | Mac | 1.5h | RBAC 已完成 |
| **P1** | 管理后台文章编辑器增强（Markdown 预览 + 全屏） | Legion | 1.5h | 无 |
| **P1** | 前端 Bundle 体积优化 + 路由懒加载 + CDN 拆分 | Legion | 2h | 无 |
| **P1** | ESLint 规则全面升级 + 全量修复 | Legion | 1.5h | 无 |
| **P2** | 微信小程序分享卡片 + 订阅消息接入 | Legion | 1.5h | 无 |
| **P2** | Swagger API 文档全面完善 | Legion | 1h | 无 |
| **P2** | 管理后台数据导出（Excel/CSV）功能 | Mac | 1h | 无 |
| **P2** | 项目 README + 部署文档中英双语化 | Legion | 1h | 无 |

> **Mac 合计**：约 10.5h（核心攻坚，可弹性取舍 P2）
> **Legion 合计**：约 10h（质量 + 体验，稳步推进）
> **实际单日交付目标**：P0 全部 + P1 大部分（约 8h/台），P2 弹性推进

---

## 二、Mac 主力机任务详单

### 🎯 P0-1：接口限流防刷中间件（1.5h）

**负责**：Mac
**文件**：
- 新建 `sanmoo-server-go/internal/interfaces/http/middleware/rate_limit_middleware.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/router/router.go`

**具体工作**：
1. 基于 Redis 实现滑动窗口限流（INCR + EXPIRE 原子操作 / Lua 脚本）
2. 分级限流策略：
   - 公开读接口（文章列表/详情/分类/标签）：60次/分钟/IP
   - 公开写接口（点赞/搜索记录）：10次/分钟/IP
   - 搜索接口：20次/分钟/IP（保护 Meilisearch）
   - 管理后台接口：300次/分钟/用户（JWT 身份限流）
   - 认证接口（登录/验证码）：5次/分钟/IP（防暴力破解）
3. 超限返回 429 + Retry-After 响应头
4. 点赞接口额外防刷：同一 IP 对同一文章 24h 内只能点 1 次（Redis SETNX）
5. 中间件支持白名单（如内网 IP、健康检查路径）

**验收**：压测 `ab -n 100 -c 10` 验证前 60 次 200，后续 429

---

### 🎯 P0-2：文章 URL 伪静态化 + Slug 全链路（2.5h）

**负责**：Mac
**文件**：
- 新建 `sanmoo-server-go/migrations/20260707_add_article_slug.sql`
- 修改 `sanmoo-server-go/internal/domain/article/model.go`
- 修改 `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/article_repo.go`
- 修改 `sanmoo-server-go/internal/application/article/service.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/handler/web_handler.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/handler/admin_article_handler.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/router/router.go`
- 修改 `sanmoo-vite/src/App.tsx`
- 修改 `sanmoo-vite/src/pages/web/ArticleDetail.tsx`
- 修改 `sanmoo-vite/src/pages/web/components/ArticleCard.tsx`
- 修改 `sanmoo-vite/src/pages/admin/components/ArticleEditorDrawer.tsx`
- 修改 `sanmoo-vite/src/services/blog/article-api.ts`
- 修改 `sanmoo-vite/src/services/blog/types.ts`

**具体工作**：
1. **数据库**：`t_article` 新增 `slug` 字段（varchar(100), UNIQUE, NULLABLE），并为现有文章自动生成 slug（用 id + 拼音/英文标题）
2. **后端 Model + Repo**：新增 `GetBySlug` 方法，Create/Update 支持 slug
3. **后端 Service**：
   - 自动生成 slug 逻辑：标题转拼音（引入 `github.com/mozillazg/go-pinyin`），全小写，空格转 `-`，去特殊字符
   - 重复检测：冲突则追加 `-2`、`-3`
   - 文章详情支持双路径查询（slug 或 id）
4. **后端路由**：
   - 新增 `/web/articles/slug/:slug` 路由
   - 原 `/web/articles/:id` 若检测到文章有 slug，返回 301 重定向到 slug 版本
   - Sitemap 全部输出 slug URL
5. **前端路由**：新增 `/article/:slug` 页面
6. **前端列表**：ArticleCard 链接优先用 slug，fallback 到 id
7. **后台编辑器**：slug 输入框 + 「从标题生成」按钮 + 重名检测

**验收**：
- 新文章自动生成 slug，可手动编辑
- `/article/52` 自动 301 到 `/article/xxx-slug`
- Sitemap 输出 slug 链接
- 后台编辑 slug 即时校验唯一性

---

### 🎯 P0-3：文章定时发布 + 调度器（2h）

**负责**：Mac
**文件**：
- 新建 `sanmoo-server-go/migrations/20260707_add_scheduled_publish.sql`
- 修改 `sanmoo-server-go/internal/domain/article/model.go`
- 修改 `sanmoo-server-go/internal/infrastructure/repository/mysqlrepo/article_repo.go`
- 修改 `sanmoo-server-go/internal/application/article/service.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/handler/admin_article_handler.go`
- 修改 `sanmoo-server-go/internal/bootstrap/app.go`（启动调度器）
- 修改 `sanmoo-vite/src/pages/admin/components/ArticleEditorDrawer.tsx`
- 修改 `sanmoo-vite/src/pages/admin/Articles.tsx`
- 修改 `sanmoo-vite/src/services/blog/types.ts`

**具体工作**：
1. **数据库**：`t_article` 新增 `publish_time` 字段（datetime, NULLABLE）
2. **后端调度**：
   - 引入 `robfig/cron/v3` 或自实现简易 ticker（每分钟检查）
   - 调度器在 `bootstrap/app.go` 启动，检查 `is_published=0 AND publish_time IS NOT NULL AND publish_time <= NOW()` 的文章
   - 自动发布：设置 `is_published=1`、清空 `publish_time`、更新 `update_time`
   - 发布后联动：清理文章列表缓存、同步 Meilisearch 索引、触发 RSS 更新
3. **后台 API**：创建/编辑文章支持传入 `publish_time`
4. **前端编辑器**：
   - 「定时发布」Switch，开启后显示 DatePicker（含时分）
   - 校验：发布时间必须晚于当前时间
   - 状态显示：草稿 / 待发布 / 已发布
5. **前端文章列表**：
   - 状态筛选增加「待发布」
   - 待发布文章显示时钟图标 + 预计发布时间

**验收**：
- 设置 2 分钟后发布的文章，时间到自动发布
- 前台在发布前不可见
- 列表状态正确显示

---

### 🎯 P1-1：文章阅读体验全面升级（2h）

**负责**：Mac
**文件**：
- 修改 `sanmoo-vite/src/pages/web/ArticleDetail.tsx`
- 修改 `sanmoo-vite/src/pages/web/articleDetail.css`
- 修改 `sanmoo-vite/src/pages/web/components/SimpleMarkdown.tsx`（或对应 markdown 渲染组件）

**具体工作**：
1. **阅读进度条**（0.5h）：
   - 页面顶部固定 3px 渐变色进度条
   - 基于 `window.scrollY` + 文档高度计算进度
   - 使用 `requestAnimationFrame` 节流，滚动时显示，停止 1s 后淡出

2. **代码块增强**（0.7h）：
   - 代码块右上角添加「复制」按钮（hover 显示）
   - 点击复制整段代码，成功显示 ✓ 动画
   - 代码块顶部语言标签（```go → 显示 Go）
   - 代码块圆角 + 语法高亮主题微调

3. **图片灯箱**（0.5h）：
   - 文章内图片点击放大，支持左右切换
   - 自实现简易 Lightbox（遮罩 + 居中大图 + 关闭按钮）
   - 支持 ESC 关闭、点击遮罩关闭

4. **字数 & 阅读时间**（0.3h）：
   - 前端计算文章正文字数（去除 markdown 标记）
   - 按 400 字/分钟估算阅读时间
   - 文章元信息区域显示「约 X 字 · 阅读 Y 分钟」

**验收**：
- 滚动时顶部进度条平滑变化
- 代码块复制按钮可用，复制成功有反馈
- 图片点击放大，ESC 可关闭

---

### 🎯 P1-2：RBAC 菜单级权限细化 + 前端动态路由（1.5h）

**负责**：Mac
**文件**：
- 修改 `sanmoo-server-go/internal/domain/permission/model.go`（增加前端路径字段）
- 修改 `sanmoo-vite/src/store/usePermStore.ts`
- 修改 `sanmoo-vite/src/pages/Admin.tsx`
- 修改 `sanmoo-vite/src/App.tsx`

**具体工作**：
1. **后端**：权限表增加 `front_path`、`icon`、`component`、`sort_order` 等字段（用于前端菜单渲染）
2. **后端**：新增「获取当前用户菜单树」接口，返回有权限的菜单结构
3. **前端**：
   - 登录后拉取菜单树，存入 usePermStore
   - Admin 布局根据菜单树动态渲染侧边栏
   - 路由守卫：无权限的路由 403 或隐藏
   - 按钮级权限：`PermGuard` 组件已有，补充更多使用场景

**验收**：
- 不同角色登录看到不同菜单
- 无权限路由直接访问被拦截
- 权限变更后刷新菜单即时生效

---

### 🎯 P2-1：管理后台数据导出（Excel/CSV）（1h）

**负责**：Mac（时间充裕则做）
**文件**：
- 修改 `sanmoo-server-go/internal/interfaces/http/handler/admin_article_handler.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/handler/admin_user_handler.go`
- 修改 `sanmoo-vite/src/pages/admin/Articles.tsx`
- 修改 `sanmoo-vite/src/pages/admin/Users.tsx`

**具体工作**：
1. 后端新增文章列表 CSV 导出接口
2. 后端新增用户列表 CSV 导出接口
3. 前端列表页增加「导出」按钮
4. 导出文件名带日期，如 `articles_20260707.csv`

**验收**：点击导出下载 CSV，用 Excel 打开正常

---

### 📊 Mac 当日排期表

```
09:00 - 10:30  P0-1 接口限流防刷中间件（1.5h）
10:30 - 10:45  休息
10:45 - 12:15  P0-2 Slug 全链路（上）- 数据库 + 后端（1.5h）

14:00 - 15:00  P0-2 Slug 全链路（下）- 前端适配（1h）
15:00 - 17:00  P0-3 文章定时发布（2h）
17:00 - 17:15  休息
17:15 - 18:45  P1-1 文章阅读体验升级（1.5h）

弹性（晚上）：
  - P1-2 RBAC 菜单级权限（1.5h）
  - P2-1 数据导出（1h）
```

---

## 三、Legion 助攻机任务详单

### 🎯 P0-4：访问日志自动清理 + 数据保留策略（1.5h）

**负责**：Legion
**文件**：
- 新建 `sanmoo-server-go/internal/application/maintenance/service.go`（维护服务）
- 修改 `sanmoo-server-go/internal/bootstrap/app.go`
- 修改 `sanmoo-server-go/internal/interfaces/http/handler/admin_setting_handler.go`（或新增 maintenance handler）
- 修改 `sanmoo-server-go/internal/interfaces/http/router/router.go`
- 修改 `sanmoo-vite/src/pages/admin/Settings.tsx`
- 新建 `sanmoo-vite/src/pages/admin/settings/MaintenanceTab.tsx`

**具体工作**：
1. **后端清理服务**：
   - 新增 `CleanupExpiredLogs` 方法
   - 清理规则（默认值，后续可配置）：
     - `t_access_log`：保留 90 天
     - `t_error_log`：保留 180 天
     - `t_search_history`：保留 90 天
     - `t_mp_browse_history`：保留 180 天
     - `t_statistics_article_pv`：保留 365 天（聚合数据可保留更久）
   - 每次清理记录日志：清理了多少条、耗时
2. **调度器**：每日凌晨 3:00 自动执行（与 P0-3 调度器复用框架）
3. **后台 API**：
   - `POST /admin/maintenance/cleanup-logs` 手动触发清理
   - `GET /admin/maintenance/stats` 获取各表数据量统计
4. **前端设置页**：新增「数据维护」Tab
   - 显示各表当前数据量
   - 「立即清理过期数据」按钮（带确认弹窗）
   - 清理进度 / 结果提示

**验收**：
- 手动调用清理接口，过期数据被删除
- 各表数据量正确显示
- 清理后数据库表空间释放（可用 `SHOW TABLE STATUS` 验证）

---

### 🎯 P1-3：管理后台文章编辑器增强（1.5h）

**负责**：Legion
**文件**：
- 修改 `sanmoo-vite/src/pages/admin/components/ArticleEditorDrawer.tsx`
- 修改 `sanmoo-vite/src/pages/admin/components/ArticleList.tsx`

**具体工作**：
1. **编辑器全屏模式**（0.5h）：
   - 编辑器增加「全屏编辑」按钮
   - 点击后编辑器占满整个屏幕（z-index 高优先级）
   - ESC 或再次点击退出全屏

2. **Markdown 实时预览**（0.7h）：
   - 编辑器左右分栏：左侧编辑，右侧预览
   - 预览样式与前台文章详情保持一致
   - 同步滚动（可选，先做分栏即可）
   - 使用现有的 SimpleMarkdown 组件渲染

3. **其他小优化**（0.3h）：
   - 标题输入框字数统计（建议 30-70 字最佳 SEO 长度）
   - 描述输入框字数统计（建议 120-160 字）
   - 快捷插入：一键插入代码块、链接、图片 Markdown 语法

**验收**：
- 全屏模式正常切换
- 左右分栏预览同步
- 字数统计实时更新

---

### 🎯 P1-4：前端 Bundle 体积优化 + 路由懒加载（2h）

**负责**：Legion
**文件**：
- 修改 `sanmoo-vite/vite.config.ts`
- 修改 `sanmoo-vite/src/App.tsx`
- 修改 `sanmoo-vite/src/main.tsx`
- 修改 `sanmoo-vite/package.json`（新增分析脚本）

**具体工作**：
1. **路由级代码分割**（0.5h）：
   - 所有页面路由改为 `React.lazy` + `Suspense` 懒加载
   - 管理后台 / 前台 / 登录页分别拆包
   - 添加加载中占位（Spinner）

2. **依赖优化**（0.8h）：
   - 运行 `rollup-plugin-visualizer` 分析 bundle 组成
   - Ant Design 按需引入（检查是否已配置）
   - 大依赖评估：`echarts` / `recharts` 是否可以按需加载
   - `moment` → `dayjs` 替换（如果用了 moment）
   - lodash 按需引入（`lodash-es` 或 `lodash/xxx`）

3. **生产构建优化**（0.5h）：
   - Vite 构建开启 `terserOptions` 去除 console + debugger
   - 配置 `manualChunks`：vendor / antd / echarts 分 chunk
   - gzip / brotli 压缩（构建时生成 .gz 文件，配合 Nginx）
   - 图片资源优化：SVG 内联，小图 base64 阈值调整

4. **分析报告**（0.2h）：
   - package.json 增加 `analyze` 脚本
   - 输出优化前后体积对比数据

**验收**：
- 首屏 JS 体积减少 30%+
- 路由切换时按需加载对应 chunk
- `pnpm build` 构建成功

---

### 🎯 P1-5：ESLint 规则全面升级 + 全量修复（1.5h）

**负责**：Legion
**文件**：
- 修改 `sanmoo-vite/eslint.config.js`
- 各业务组件文件（修复 lint 错误）

**具体工作**：
1. **升级规则**（0.4h）：
   - 启用 `@typescript-eslint/no-unused-vars`（warn → error）
   - 启用 `@typescript-eslint/no-explicit-any`（warn，逐步收紧）
   - 启用 `import/order` 分组排序规则
   - 启用 `react-refresh/only-export-components`
   - 启用 `@typescript-eslint/consistent-type-imports`
   - 启用 `no-console`（生产环境 error，开发 warn）

2. **全量修复**（1h）：
   - 运行 `pnpm lint` 列出所有问题
   - 批量修复可自动修复的（`--fix`）
   - 手动修复剩余问题：未使用的变量、`any` 类型标注不规范等
   - 特殊情况加 `eslint-disable-next-line` 并注释原因

3. **CI 钩子（可选）**（0.1h）：
   - 配置 `lint-staged` + `husky`（如未配置）
   - 提交代码自动 lint 检查

**验收**：
- `pnpm lint` 零 error
- TypeScript 类型检查通过

---

### 🎯 P2-2：微信小程序分享卡片 + 订阅消息（1.5h）

**负责**：Legion
**文件**：
- 修改 `sanmoo-mp/miniprogram/pages/article-detail/index.ts`
- 修改 `sanmoo-mp/miniprogram/pages/index/index.ts`
- 修改 `sanmoo-mp/miniprogram/pages/topic-detail/index.ts`
- 修改 `sanmoo-server-go/internal/application/mpuser/subscribe_service.go`
- 修改 `sanmoo-server-go/internal/application/article/service.go`（发布时触发）

**具体工作**：
1. **小程序分享优化**（0.6h）：
   - 文章详情页 `onShareAppMessage`：标题=文章标题，路径=`/pages/article-detail/index?id=xxx`，图片=文章题图
   - 文章详情页 `onShareTimeline`：朋友圈分享配置
   - 首页分享：标题=博客名+介绍，图片=Logo
   - 专题详情页分享：标题=专题名，图片=专题封面

2. **订阅消息接入**（0.9h）：
   - 文章底部增加「订阅更新提醒」按钮
   - 点击调用 `wx.requestSubscribeMessage` 申请一次性订阅
   - 用户同意后，后端记录订阅关系到 `t_mp_user_subscribe`（已有此表，看是否够用）
   - 新文章发布时，给所有订阅用户发送订阅消息
   - 需要订阅消息模板 ID（可先写配置项，后续在小程序后台申请）

**验收**：
- 分享卡片显示正确的标题和封面图
- 订阅按钮可唤起授权弹窗
- 授权成功后端有记录

---

### 🎯 P2-3：Swagger API 文档全面完善（1h）

**负责**：Legion
**文件**：
- `sanmoo-server-go/internal/interfaces/http/handler/` 下各 handler 文件
- `sanmoo-server-go/internal/interfaces/http/dto/` 下各 DTO

**具体工作**：
1. 为以下模块补全 Swagger 注解：
   - 认证模块（登录、刷新、验证码）
   - 文章模块（前台 + 后台全部接口）
   - 分类 / 标签 / 专题模块
   - 仪表盘统计接口
   - 友情链接接口
2. 每个接口标注：`@Summary`、`@Description`、`@Tags`、`@Accept`、`@Produce`、`@Param`、`@Success`、`@Failure`
3. 统一响应结构体标注
4. 运行 `swag init` 生成最新文档，验证 `/swagger` 可正常访问

**验收**：访问 `/swagger`，所有核心接口有清晰的中文说明和参数示例

---

### 🎯 P2-4：README + 部署文档中英双语化（1h）

**负责**：Legion
**文件**：
- 修改 `README.md`（中英双语）
- 修改 `DEPLOY.md`（补充优化）
- 新建 `README_EN.md`（可选，或同文件分章节）

**具体工作**：
1. README.md 重构：
   - 顶部中英文切换导航
   - 项目介绍 / 功能特性 / 技术栈 / 快速开始 / 项目结构 全部双语
   - 添加项目截图占位（或实际截图）
   - 添加 Badge（Go version、Node version、License 等）
2. DEPLOY.md 优化：
   - 目录结构优化（添加目录锚点）
   - 补充常见问题 FAQ 章节
   - 补充环境变量完整列表
3. 检查文档中的命令是否与实际项目一致（如启动命令、路径等）

**验收**：文档结构清晰，中英对照，命令可直接复制执行

---

### 📊 Legion 当日排期表

```
09:00 - 10:30  P0-4 日志自动清理 + 数据维护页（1.5h）
10:30 - 10:45  休息
10:45 - 12:15  P1-4 前端 Bundle 体积优化（1.5h）

14:00 - 15:30  P1-3 文章编辑器增强（1.5h）
15:30 - 15:45  休息
15:45 - 17:15  P1-5 ESLint 升级 + 全量修复（1.5h）
17:15 - 18:15  P2-3 Swagger 文档完善（1h）

弹性（晚上）：
  - P2-2 小程序分享 + 订阅（1.5h）
  - P2-4 README 双语化（1h）
```

---

## 四、双机协作注意事项

### 代码协作
- **分支策略**：Mac 在 `feature/mac-core` 分支，Legion 在 `feature/legion-quality` 分支，各自开发
- **冲突规避**：
  - Mac 主要改后端核心（handler/service/repo/router）+ 前端核心页面（ArticleDetail、App.tsx）
  - Legion 主要改前端质量工程（vite.config、eslint、编辑器组件、设置页）+ 后端外围（maintenance service、swagger）
  - 共同修改的文件（如 router.go、types.ts）通过约定先后顺序合并
- **合并顺序**：先合并 Mac 的 P0 核心功能，再合并 Legion 的质量优化，最后联调

### 依赖同步
- Mac 引入的新 Go 依赖（如 `go-pinyin`、`cron`），Legion 拉取后 `go mod download`
- Legion 引入的新前端依赖，Mac 拉取后 `pnpm install`

### 沟通机制
- 每个大任务完成后推送到远程，打 tag（如 `mac/p01-done`、`legion/p04-done`）
- 遇到对方模块的问题先发消息，不直接改对方负责的核心文件

---

## 五、决策思路（为什么选这些任务）

### 符合个人备案属性
- ❌ 不做评论、社区、论坛类功能（个人备案禁止）
- ✅ 强化内容属性：SEO（Slug）、阅读体验、定时发布
- ✅ 合规与安全：限流防刷、日志清理（数据不过度留存）

### 双机分工的合理性
- **Mac 做核心链路**：Slug、定时发布、限流都是牵一发而动全身的改造，需要统一架构思路
- **Legion 做质量工程**：ESLint、Bundle 优化、文档、编辑器增强都是相对独立的模块，不影响主流程，可以放心交给第二台机器

### 一天交付的可行性
- P0 级任务（4 个）是必保项，合计约 7.5h 工作量，一天完全可以完成
- P1 级任务是加分项，两台机器并行推进，预计完成 70-80%
- P2 级任务弹性最大，时间够就做，不够顺延到第二天

---

## 六、第二天及以后的储备方向（提前想深一步）

如果本日任务顺利完成，后续可继续：

1. **SEO 进阶**：JSON-LD 结构化数据、Open Graph 标签、Canonical URL、robots.txt 增强
2. **性能进阶**：图片 WebP 自动转换、CDN 适配、HTTP/2、服务端渲染（SSR）
3. **内容运营**：Markdown 批量导入导出、标签云、专栏作者系统（个人博客可简化）
4. **数据智能**：文章推荐算法优化、阅读完成度统计、访问来源分析
5. **运维体系**：Prometheus 监控、Grafana 仪表盘、告警规则、自动化部署流水线
6. **安全加固**：WAF 规则、敏感词过滤、XSS/CSRF 全面审计

---

*作战计划制定时间：2026-07-07*
*总指挥：贾维斯 · 左仆射*
