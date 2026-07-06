# Sanmoo Blog 代码质量优化计划

> 目标：在不改变原有功能的前提下，提升代码可读性、可维护性与一致性，降低后续迭代成本。

---

## 一、Go 后端（sanmoo-server-go）

### 1.1 缓存模式统一化
**现状**：`article/service.go` 中每个带缓存的方法都重复了「尝试读缓存 → 未命中则查询 → 写缓存」的模式，代码重复度高，且缓存 key 构建、TTL 选择散落在各处。

**优化方向**：
- 抽取通用缓存辅助函数（如 `cache.GetOrSet`），统一处理「读缓存 + 回源 + 写缓存」模式
- 将缓存 key 常量与 TTL 策略集中管理（目前 `cache.KeyArticleDetail` 等已部分集中，但相关文章 key 仍用字符串字面量）
- 统一缓存失效函数的调用方式，避免漏清或错清

**涉及文件**：
- `internal/application/article/service.go`
- `internal/infrastructure/cache/business.go`

**优先级**：中

---

### 1.2 Repository 层重复代码抽取
**现状**：`article_repo.go` 中 `ListArticles` 与 `ListArticlesByIDs` 存在大量重复的 row struct、Scan 字段列表、以及 Article 实体映射逻辑。`ListArticlesByIDs` 中的排序甚至使用了手写冒泡排序（O(n²)）。

**优化方向**：
- 抽取 `row` 结构体为包内共享类型
- 抽取 `mapRowToArticle` 转换函数
- 将 `ListArticlesByIDs` 中的冒泡排序替换为 `sort.Slice`（O(n log n)）
- 提取公共的「批量查询标签 + 组装」逻辑

**涉及文件**：
- `internal/infrastructure/repository/mysqlrepo/article_repo.go`

**优先级**：中

---

### 1.3 错误处理现代化
**现状**：`response.go` 中使用 `err.(*apperr.AppError)` 类型断言提取错误码，不够健壮；`errors.go` 中错误定义为 `*AppError` 指针类型，零值使用时需小心。

**优化方向**：
- 使用 `errors.As` 替代类型断言，兼容 wrapped error
- 考虑补充 `Is` 方法以支持 `errors.Is` 判断

**涉及文件**：
- `internal/shared/response/response.go`
- `internal/shared/errors/errors.go`

**优先级**：低

---

### 1.4 Handler 依赖注入简化
**现状**：`handler.go` 的 `New` 函数有 13 个参数，`bootstrap/app.go` 中组装依赖的代码也很长。后续新增领域时会持续膨胀。

**优化方向**：
- 可选：使用「选项模式（Functional Options）」或引入轻量 DI 容器（如 `google/wire` 代码生成方式）
- 若不引入新依赖，至少将 handler 按领域拆分为独立 struct（如 `AdminArticleHandler`、`WebHandler`），在 `bootstrap` 中分别注册，避免单一 `Handler` 持续膨胀

**涉及文件**：
- `internal/interfaces/http/handler/handler.go`
- `internal/bootstrap/app.go`

**优先级**：低

---

### 1.5 列表查询参数校验统一
**现状**：`handler/helpers.go` 中的 `parseIntDefault`、`parseUintDefault` 处理了参数解析，但各 handler 中分页参数、排序参数的校验逻辑散落在多处。

**优化方向**：
- 抽取统一的分页参数解析函数（`parsePagination(c)`）
- 补充对 page、size 的上下限保护（防止 size 过大导致慢查询）

**涉及文件**：
- `internal/interfaces/http/handler/helpers.go`
- 各 handler 文件

**优先级**：中

---

## 二、React 前端（sanmoo-vite）

### 2.1 管理后台 CRUD 页面逻辑复用
**现状**：`Tags.tsx`、`Categories.tsx`、`Topics.tsx`、`Links.tsx`、`Users.tsx` 等管理页面结构高度一致——都是「搜索框 + 表格 + 分页 + 新建/编辑弹窗 + 批量删除」，但每个文件都从零开始写一遍状态管理（loading、list、current、pageSize、total、searchText、selectedRowKeys、editing、open）和加载逻辑。

**优化方向**：
- 抽取通用 `useCrudTable` Hook，封装列表加载、分页、搜索、选中、弹窗状态
- 抽取通用 `CrudPage` 组件，统一卡片样式、面包屑、搜索区、表格、分页的布局
- 各业务页面只需传入列配置、API 函数、表单配置即可

**涉及文件**：
- `src/pages/admin/Tags.tsx`
- `src/pages/admin/Categories.tsx`
- `src/pages/admin/Topics.tsx`
- `src/pages/admin/Links.tsx`
- `src/pages/admin/Users.tsx`
- （新增）`src/hooks/useCrudTable.ts`
- （新增）`src/pages/admin/components/CrudPage.tsx`

**优先级**：高（收益最大，减少约 60% 重复代码）

---

### 2.2 充分利用 TanStack Query
**现状**：项目已安装 `@tanstack/react-query`，但几乎所有页面仍在手写 `useState + useEffect + loading/error` 状态管理。例如 `Tags.tsx` 中的 `load` 函数 + 两个 `useEffect` 触发加载，完全可以用 `useQuery` 替代。

**优化方向**：
- 用 `useQuery` 替代列表/详情等只读数据的加载逻辑，自动处理 loading、error、缓存、重试
- 用 `useMutation` 替代新增/编辑/删除等写操作，自动处理乐观更新、失效重查
- 统一管理 Query Key，便于缓存失效

**涉及文件**：
- 所有管理后台页面
- （新增）`src/services/blog/queryKeys.ts`

**优先级**：高（大幅减少状态管理样板代码，提升数据一致性）

---

### 2.3 request.ts 与状态管理整合
**现状**：`request.ts` 中的 token 刷新逻辑（`isRefreshing`、`failedQueue`、`processQueue`）是独立的闭包状态，与 `useAuthStore`（zustand）割裂。token 的存取通过 `@/utils/auth` 的 localStorage 工具函数直接操作，而非走 store。

**优化方向**：
- 将 token 刷新队列、当前 token 状态统一纳入 `useAuthStore` 管理
- `request.ts` 从 store 读取 token 和触发刷新，确保状态单一数据源
- `redirectToLogin` 也改为调用 store 的登出 action

**涉及文件**：
- `src/services/request.ts`
- `src/store/useAuthStore.ts`
- `src/utils/auth.ts`

**优先级**：中

---

### 2.4 WebShell 组件拆分
**现状**：`WebShell.tsx` 单文件 346 行，同时承担了顶部导航、右侧栏、底部 Footer、搜索弹窗等多个职责，可读性较差。

**优化方向**：
- 拆分为 `WebHeader`、`WebSidebar`、`WebFooter` 三个子组件
- `WebShell` 仅负责布局组装和状态传递

**涉及文件**：
- `src/pages/web/components/WebShell.tsx`
- （新增）`src/pages/web/components/WebHeader.tsx`
- （新增）`src/pages/web/components/WebSidebar.tsx`
- （新增）`src/pages/web/components/WebFooter.tsx`

**优先级**：中

---

### 2.5 样式常量与内联样式治理
**现状**：
- `WebShell.tsx`、`Tags.tsx` 等文件中大量使用内联样式对象（如 `cardStyle`、`sidebarWidth = 300`、`containerMaxWidth = 1200`）
- 同一份卡片样式（圆角 20px、边框、阴影）在多个管理页面重复定义

**优化方向**：
- 抽取布局常量到 `src/styles/layout.ts`（如 `SIDER_WIDTH`、`CONTAINER_MAX_WIDTH`、`CARD_RADIUS`）
- 用 `antd-style` 的 `createStyles` 或 CSS Variables 替代内联样式，减少渲染时对象重建
- 管理后台卡片样式封装为统一的 `AdminCard` 组件

**涉及文件**：
- `src/pages/web/components/WebShell.tsx`
- 各管理页面
- （新增）`src/styles/layout.ts`

**优先级**：低

---

### 2.6 ESLint 规则完善
**现状**：`eslint.config.js` 仅启用了基础推荐规则，未启用 `@typescript-eslint/no-unused-vars`、`@typescript-eslint/no-explicit-any` 等有助于代码质量的规则。

**优化方向**：
- 逐步启用更严格的 TypeScript ESLint 规则
- 补充 `import/order` 规则统一 import 排序
- 配置 `eslint-plugin-react-refresh` 的组件命名检查

**涉及文件**：
- `eslint.config.js`

**优先级**：低

---

## 三、微信小程序（sanmoo-mp）

### 3.1 request.ts 职责拆分
**现状**：`api/request.ts` 同时承担了：请求封装、OpenID 存储、wx.login 节流、OpenID 获取重试（指数退避）等多个职责，文件 180 行，且与 `api/mp.ts` 中的 `ensureMpOpenid` 存在重复/交叉引用。

**优化方向**：
- 将 OpenID 认证相关逻辑抽取到独立的 `api/auth.ts` 或 `utils/auth.ts`
- `request.ts` 只负责纯粹的 HTTP 请求封装和统一错误处理
- 统一 `ensureMpOpenid` 的导出位置，避免两个文件都导出

**涉及文件**：
- `miniprogram/api/request.ts`
- `miniprogram/api/mp.ts`
- （新增）`miniprogram/utils/auth.ts`

**优先级**：中

---

### 3.2 页面列表加载逻辑复用
**现状**：首页（`pages/index/index.ts`）、分类页、标签页、收藏页、历史页等都有「初始化加载 + 下拉刷新 + 触底加载更多 + loading 状态」的相似逻辑，但各自实现。

**优化方向**：
- 抽取 `paginationBehavior`（或叫 `listBehavior`），封装 `page`、`size`、`total`、`list`、`loading` 状态以及 `loadMore`、`refresh`、`onReachBottom` 等方法
- 各页面只需提供「加载指定页」的具体实现

**涉及文件**：
- `miniprogram/pages/index/index.ts`
- `miniprogram/pages/categories/index.ts`
- `miniprogram/pages/tags/index.ts`
- `miniprogram/pages/favorites/index.ts`
- `miniprogram/pages/history/index.ts`
- （新增）`miniprogram/behaviors/pagination.ts`

**优先级**：中

---

### 3.3 夜间模式状态管理统一
**现状**：夜间模式状态通过 `app.globalData.nightMode` 存储，每个页面在 `onShow` 时手动读取并同步到 `data.nightMode`。修改主题依赖全局变量，页面间同步靠各自读取。

**优化方向**：
- 封装 `useNightMode` 工具函数（或 behavior），统一处理读取、切换、导航栏样式应用
- 考虑使用小程序的 `EventChannel` 或全局事件总线，在主题切换时通知所有页面更新

**涉及文件**：
- `miniprogram/utils/night-mode.ts`
- 各页面

**优先级**：低

---

### 3.4 依赖清理
**现状**：`package.json` 的 `dependencies` 中有大量与小程序运行无关的包（`express`、`hono`、`axios`、`koa`、`react` 相关、`zod` 等上百个），疑似误安装或为 MCP 工具依赖但放在了错误的位置。这些依赖会增加 `node_modules` 体积，且可能造成混淆。

**优化方向**：
- 逐一核对，移除小程序运行时不需要的依赖
- 将开发/工具类依赖移到 `devDependencies`
- 重新安装依赖并验证小程序正常运行

**涉及文件**：
- `package.json`

**优先级**：高（减少依赖体积，避免安全隐患）

---

### 3.5 TypeScript 版本评估
**现状**：使用 TypeScript 6.0.2，版本较新，需确认微信小程序 TS 编译器的兼容性。若小程序基础库或编译工具链不支持，可能存在隐性问题。

**优化方向**：
- 确认小程序编译工具链对 TS 6 的支持情况
- 如有兼容性问题，降级到 LTS 版本（如 5.x）

**涉及文件**：
- `package.json`
- `tsconfig.json`

**优先级**：低

---

## 四、跨端 / 全局优化

### 4.1 API 类型一致性
**现状**：后端 Go 的 DTO、前端 TypeScript 的类型定义、小程序的类型定义三者各自维护，可能存在不一致。

**优化方向**：
- 可选：从后端 OpenAPI / Swagger 自动生成前端 + 小程序的 TypeScript 类型定义（如使用 `openapi-typescript`）
- 若不引入自动化，至少建立「类型定义以哪个为准」的约定，并在修改接口时同步更新

**优先级**：低

---

### 4.2 错误码与错误消息统一
**现状**：后端错误码定义在 `internal/shared/errors/errors.go`，前端通过 `errorCode` 字段判断错误类型，但前端没有集中的错误码常量映射。

**优化方向**：
- 前端新增 `src/constants/errorCodes.ts`，集中管理错误码常量
- 统一错误处理策略（如特定错误码弹出特定提示、特定错误码触发重新登录）

**涉及文件**：
- （新增）`src/constants/errorCodes.ts`

**优先级**：低

---

## 五、实施建议

### 优先级排序
1. **高优先级**（收益大、改动可控）
   - 前端：CRUD 页面逻辑复用（2.1）
   - 前端：TanStack Query 推广使用（2.2）
   - 小程序：依赖清理（3.4）

2. **中优先级**（收益中等、改动不大）
   - Go 后端：缓存模式统一化（1.1）
   - Go 后端：Repository 层重复代码抽取（1.2）
   - Go 后端：列表查询参数校验统一（1.5）
   - 前端：request 与状态管理整合（2.3）
   - 前端：WebShell 组件拆分（2.4）
   - 小程序：request.ts 职责拆分（3.1）
   - 小程序：页面列表加载逻辑复用（3.2）

3. **低优先级**（锦上添花、可延后）
   - 其余所有低优先级项

### 实施原则
- 每一项优化单独开分支，确保可回滚
- 优化前后运行现有测试（如有）+ 手动核心功能验证
- 优先做「纯重构、不改行为」的优化，再做涉及模式迁移的优化
