# Sanmoo Blog

一个面向个人原创内容的现代化博客系统，帮助技术创作者沉淀长期价值。

> 以简约、自然、确定的方式沉淀长期技术价值。

## 定位

Sanmoo Blog 专注于 **个人原创内容站**，为独立技术创作者提供：

- **简洁的创作体验**：无干扰的写作环境，专注内容本身
- **优雅的阅读体验**：响应式设计，支持深色模式，保护读者眼睛
- **完整的内容管理**：文章、分类、标签、专题一站式管理
- **合规的隐私保护**：完善的隐私政策、备案信息展示、数据保留说明
- **多端访问支持**：Web 端 + 微信小程序，内容触达更多读者

## 技术栈

- **后端**: Go 1.21+、Gin、GORM、MySQL、Redis、Meilisearch
- **前端**: React 18、TypeScript、Vite、Ant Design、TailwindCSS
- **小程序**: 原生微信小程序框架
- **部署**: Docker Compose

## 功能特性

### 内容创作
- 文章管理（创建、编辑、发布、草稿、回收站）
- Markdown 富文本编辑器
- 分类与标签体系
- 专题页面管理
- 归档页面

### 阅读体验
- 响应式设计，适配桌面端与移动端
- 深色/浅色模式切换
- 文章目录导航
- 搜索功能（基于 Meilisearch）
- RSS 订阅

### 站点配置
- 站点信息管理（标题、副标题、描述、Logo）
- 合规配置（隐私政策、备案信息、联系方式、数据保留说明、账号注销说明）
- 友情链接管理
- 系统统计仪表盘

### 合规特性
- 隐私政策页面（Web + 小程序）
- ICP 备案信息展示
- 数据保留策略说明
- 用户账号注销功能

### 小程序
- 文章列表与详情
- 书签收藏
- 阅读记录
- 订阅通知
- 隐私政策与账号注销

## 快速开始

### 环境要求

- Go 1.21+
- Node.js 20+
- MySQL 8.0+（可选，推荐使用 Docker）
- Docker Desktop（Windows/macOS 推荐）

### 本地开发

#### Windows 环境（Docker Desktop）

```bash
git clone https://github.com/heicoder-wuyunbin/sanmoo-blog.git
cd sanmoo-blog

docker compose up -d mysql redis meilisearch

docker exec -it mysql mysql -uroot -proot1234 -e "CREATE DATABASE IF NOT EXISTS sanmoo_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

cd sanmoo-server-go
go mod download
cp .env.example .env
go run cmd/server/main.go

cd sanmoo-vite
pnpm install
pnpm dev
```

**访问地址：**
- **博客前台**: `http://localhost:8000`
- **管理后台**: `http://localhost:8000/admin`
- **账号**: `admin`
- **密码**: `test1234`

#### macOS 环境（Homebrew）

```bash
git clone https://github.com/heicoder-wuyunbin/sanmoo-blog.git
cd sanmoo-blog

brew services start mysql
brew services start redis
brew services start meilisearch

mysql -uroot -proot1234 -e "CREATE DATABASE IF NOT EXISTS sanmoo_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

cd sanmoo-server-go
go mod download
cp .env.example .env
go run cmd/server/main.go

cd sanmoo-vite
pnpm install
pnpm dev
```

### Docker 部署

```bash
docker compose up -d
```

## 项目结构

```
sanmoo-blog/
├── sanmoo-server-go/    # 后端服务
│   ├── cmd/             # 命令入口
│   ├── internal/        # 业务逻辑
│   ├── migrations/      # 数据库迁移
│   ├── public/          # 静态资源
│   └── go.mod
├── sanmoo-vite/         # Web 前端
│   ├── src/
│   │   ├── pages/       # 页面组件（前台 + 管理后台）
│   │   ├── services/    # API 服务
│   │   ├── components/  # 公共组件
│   │   └── styles/      # 样式文件
│   └── package.json
├── sanmoo-mp/           # 微信小程序
│   └── miniprogram/
│       ├── pages/       # 小程序页面
│       ├── api/         # API 封装
│       └── utils/       # 工具函数
├── docker-compose.yml   # Docker Compose 配置
├── deploy.sh            # 部署脚本
└── DEPLOY.md            # 部署文档
```

## 配置说明

### 后端配置

复制 `.env.example` 为 `.env`，修改以下配置：

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

修改 `sanmoo-vite/.env`：

```env
VITE_API_BASE_URL=http://localhost:8080
```

## 部署

详细部署说明请参考 [DEPLOY.md](DEPLOY.md)。

## 许可证

MIT License