# Sanmoo Blog

一个基于 Go + React 的现代化个人博客系统。

## 技术栈

- **后端**: Go 1.21+、Gin、GORM、MySQL
- **前端**: React 18、TypeScript、Vite、Ant Design
- **部署**: Docker Compose

## 功能特性

### 前台功能
- 文章列表与详情页
- 分类与标签
- 专题页面
- 归档页面
- 友情链接
- 搜索功能
- RSS 订阅
- SEO 优化（JSON-LD、面包屑导航）

### 后台管理
- 文章管理（CRUD、富文本编辑器）
- 分类与标签管理
- 友情链接管理
- 用户管理
- 系统配置
- 数据统计仪表盘

## 快速开始

### 环境要求

- Go 1.21+
- Node.js 20+
- MySQL 8.0+
- Docker（可选）

### 本地开发

```bash
# 克隆项目
git clone https://github.com/sanmoo/sanmoo-blog.git
cd sanmoo-blog

# 后端开发
cd sanmoo-server-go
go mod download
cp .env.example .env
# 修改 .env 配置数据库连接
go run main.go

# 前端开发
cd sanmoo-vite
pnpm install
pnpm dev
```

### Docker 部署

```bash
docker-compose up -d
```

## 项目结构

```
sanmoo-blog/
├── sanmoo-server-go/    # 后端服务
│   ├── internal/        # 业务逻辑
│   ├── migrations/      # 数据库迁移
│   ├── public/          # 静态资源
│   └── main.go          # 入口文件
├── sanmoo-vite/         # 前端项目
│   ├── src/
│   │   ├── pages/       # 页面组件
│   │   ├── services/    # API 服务
│   │   └── components/  # 公共组件
│   └── package.json
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
