# Sanmoo Blog

**个人原创技术内容发布与知识整理平台**

> 以简约、自然、确定的方式沉淀长期技术价值。

## 定位

Sanmoo Blog 是个人备案的独立博客系统，专注提供：

- **个人原创内容发布**：无干扰的写作环境，专注技术内容创作
- **知识专题化沉淀**：通过专题将零散文章组织成系统化学习路径
- **双端内容分发**：Web 端做 SEO 与公开搜索，小程序做移动端轻阅读
- **轻量化运营**：只保留个人站长真正长期使用的管理功能

### 我们是什么

- 个人技术博客，专注原创内容发布与知识整理
- 内容以专题为核心组织，提供系统化阅读体验
- 支持 Web + 微信小程序双端内容分发

### 我们不是什么

- 不开放公众注册与用户投稿
- 不做评论社区与社交互动
- 不做商业交易、会员付费、广告投放
- 不做用户等级成长与重运营型推荐系统

## 技术栈

- **后端**: Go 1.21+、Gin、GORM、MySQL、Redis、Meilisearch
- **前端**: React 18、TypeScript、Vite、Ant Design、TailwindCSS
- **小程序**: 原生微信小程序框架
- **部署**: Docker Compose

## 功能特性

### 内容创作
- 文章管理（创建、编辑、发布、草稿）
- Markdown 编辑器
- 分类与标签体系
- 专题管理（知识体系化沉淀）
- 归档页面

### 阅读体验
- 响应式设计，适配桌面端与移动端
- 深色 / 浅色模式切换
- 文章目录导航
- 全文搜索（基于 Meilisearch）
- RSS 订阅

### 站点配置
- 站点品牌信息（标题、介绍、头像、海报）
- 合规配置（政策、备案信息、联系方式、数据保留、账号注销）
- 渠道配置（社交链接、微信）
- 基础设施配置（搜索、存储、邮件）

### 合规特性
- 政策页面（Web + 小程序）
- ICP 备案信息展示
- 数据保留策略说明
- 用户账号注销功能

### 小程序
- 文章列表与详情
- 书签收藏
- 阅读记录
- 订阅通知
- 政策与账号注销

## 快速开始

### 环境要求

- Go 1.21+
- Node.js 20+
- MySQL 8.0+
- Redis
- Meilisearch

### 本地开发

```bash
git clone https://github.com/heicoder-wuyunbin/sanmoo-blog.git
cd sanmoo-blog

# 启动基础设施
docker compose up -d mysql redis meilisearch

# 创建数据库
docker exec -it mysql mysql -uroot -proot1234 -e "CREATE DATABASE IF NOT EXISTS sanmoo_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# 启动后端
cd sanmoo-go
go mod download
cp .env.example .env
go run cmd/server/main.go

# 启动前端
cd sanmoo-vite
pnpm install
pnpm dev
```

**访问地址：**
- **博客前台**: `http://localhost:8000`
- **管理后台**: `http://localhost:8000/admin`
- **默认账号**: `admin` / `test1234`

### Docker 部署

```bash
docker compose up -d
```

## 项目结构

```
sanmoo-blog/
├── sanmoo-go/           # 后端服务
│   ├── cmd/             # 命令入口
│   ├── internal/        # 业务逻辑
│   ├── migrations/      # 数据库迁移脚本
│   └── go.mod
├── sanmoo-vite/         # Web 前端
│   ├── src/
│   │   ├── pages/       # 页面组件（前台 + 管理后台）
│   │   ├── services/    # API 服务
│   │   └── components/  # 公共组件
│   └── package.json
├── sanmoo-mp/           # 微信小程序
│   └── miniprogram/
│       ├── pages/       # 小程序页面
│       ├── api/         # API 封装
│       └── utils/       # 工具函数
├── docker-compose.yml   # Docker Compose
└── sanmoo_blog_schema.sql  # 数据库 schema
```

## 配置说明

### 后端配置

```env
APP_PORT=8080
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=sanmoo_blog
REDIS_HOST=localhost
MEILISEARCH_HOST=http://localhost:7700
```

### 前端配置

```env
VITE_API_BASE_URL=http://localhost:8080
```

---

**个人备案网站** · 专注原创技术内容

