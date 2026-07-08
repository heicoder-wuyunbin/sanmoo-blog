# Sanmoo Blog 部署指南

## 📋 快速开始

### 0️⃣ Windows 11 本地开发环境 (Win11 + WSL + Docker Desktop)

适用于在 Windows 11 上使用 WSL 和 Docker Desktop 进行本地开发。

#### 推荐：高效开发模式（go run + pnpm dev）

在日常开发中，推荐使用此模式。依赖服务（MySQL、Redis、Meilisearch）通过 Docker 运行，而前端和后端直接在本地运行，利用 Vite 代理解决跨域问题，修改代码后可立即热更新，无需重新构建 Docker 镜像。

**环境要求：**
- Windows 11 22H2+
- WSL 2 (Ubuntu 26.04)
- Docker Desktop（已开启 WSL 集成）
- Go 1.22+（安装在 WSL 或 Windows 中均可）
- Node.js 22+ + pnpm（安装在 Windows 中）

**步骤一：启动依赖服务**

```bash
# 在 PowerShell 或 WSL 终端中启动基础服务
cd c:\workspace\sanmoo-blog

# 方式一：使用专用开发配置（推荐）
docker compose -f docker-compose.dev.yaml up -d

# 方式二：使用主配置文件
docker compose up -d mysql redis meilisearch

# 等待服务启动后创建数据库（首次运行）
docker exec -it mysql mysql -uroot -proot1234 -e "CREATE DATABASE IF NOT EXISTS sanmoo_blog CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
```

**步骤二：启动后端服务（WSL 终端）**

```bash
cd c:\workspace\sanmoo-blog\sanmoo-server-go

# 下载依赖（首次运行）
go mod download

# 直接运行 Go 程序
go run cmd/server/main.go

# 启动成功后，API 地址: http://localhost:28080
```

> **说明**：`application.properties` 已默认配置为连接 `localhost:3306`（MySQL）和 `localhost:6379`（Redis），与 Docker 暴露的端口一致。

**步骤三：启动前端服务（PowerShell 终端）**

```bash
cd c:\workspace\sanmoo-blog\sanmoo-vite

# 安装依赖（首次运行）
pnpm install

# 启动 Vite 开发服务器
pnpm dev

# 访问: http://localhost:8000
```

> **说明**：Vite 已配置代理（见 `vite.config.ts`），将 `/api`、`/mp`、`/uploads` 请求转发到 `http://127.0.0.1:28080`，自动解决跨域问题。

**访问方式：**

| 服务 | 地址 | 说明 |
|------|------|------|
| 前端页面 | `http://localhost:8000` | 博客首页 |
| 管理后台 | `http://localhost:8000/admin` | 管理员后台 |
| API 直连 | `http://localhost:28080/api/...` | 后端接口 |
| 测试账号 | `admin / test1234` | 管理员账号 |

**特点:**
- ✅ 热更新：修改代码后立即生效，无需重新构建
- ✅ 调试便捷：可使用 IDE 直接调试 Go 和 React 代码
- ✅ 资源占用低：仅运行必要的容器服务
- ✅ 效率提升：开发验证阶段无需等待 Docker 构建

---

#### Docker 完整部署模式

当需要验证 Docker 环境下的运行效果时，使用完整的 Docker 部署模式。

**依赖服务（Docker Desktop 运行）：**

| 服务 | Docker 镜像 | 默认端口 | 说明 |
|------|------------|---------|------|
| MySQL | `mysql:8.4` | `3306` | 数据库，root 密码：`root1234` |
| Redis | `redis:latest` | `6379` | 缓存 |
| Meilisearch | `getmeili/meilisearch:v1.49.0` | `7700` | 全文搜索 |

**启动所有服务：**

```bash
# 在 PowerShell 或 WSL 终端中执行
cd c:\workspace\sanmoo-blog

# 执行部署脚本（本地测试环境）
./deploy.sh local

# 或手动构建并启动
docker compose down
NGINX_ENV=local docker compose -f docker-compose.yaml -f docker-compose.local.yaml build --no-cache
NGINX_ENV=local docker compose -f docker-compose.yaml -f docker-compose.local.yaml up -d
```

**访问方式：**
- **地址**: `http://localhost`
- **管理后台**: `http://localhost/admin`
- **测试账号**: `admin` / `test1234`

**特点:**
- ✅ 使用 Docker Desktop 统一管理所有服务
- ✅ WSL 2 提供类 Unix 开发环境
- ✅ 数据持久化存储在 Docker Volume 中
- ✅ 与生产环境配置一致

---

### 1️⃣ MacBook Pro本地开发环境 (MacBook Pro + Homebrew)

适用于在 macOS 上使用 Homebrew 安装依赖进行本地开发。

**环境要求：**
- MacBook Pro (Apple Silicon / Intel)
- macOS 系统
- Homebrew 包管理器

**依赖服务（brew 安装）：**

| 服务 | 安装命令 | 默认端口 | 说明 |
|------|---------|---------|------|
| MySQL | `brew install mysql` | `3306` | 数据库，root 密码：`root1234` |
| Redis | `brew install redis` | `6379` | 缓存 |
| Meilisearch | `brew install meilisearch` | `7700` | 全文搜索 |

**启动服务：**

```bash
# 启动 MySQL
brew services start mysql

# 启动 Redis
brew services start redis

# 启动 Meilisearch
brew services start meilisearch
```

**数据库配置：**
- 主机：`127.0.0.1`
- 端口：`3306`
- 用户名：`root`
- 密码：`root1234`
- 数据库名：`sanmoo_blog`（需手动创建）

**前端启动：**

```bash
cd sanmoo-vite
pnpm install
pnpm dev
# 访问: http://localhost:8000
```

**后端启动：**

```bash
cd sanmoo-server-go
go mod download
go run cmd/server/main.go
# API 地址: http://localhost:28080
```

**测试账号信息：**
- **管理后台**: `http://localhost:8000/admin`
- **测试账号**: `admin`
- **测试密码**: `test1234`

**特点:**
- ✅ 本地原生运行，性能最佳
- ✅ 适合日常开发调试
- ✅ 使用 brew services 管理服务启停
- ✅ 数据库密码统一为 root

---

### 2️⃣ 生产环境部署 (HTTPS + SSL)

由于正式服务器资源有限（2核2G），采用**离线镜像部署**方式：

```bash
# 1. 在测试机构建生产镜像
./deploy.sh production

# 2. 导出离线镜像包
./deploy.sh export

# 3. 上传到正式服务器
scp sanmoo-images.tar root@backendart.com:/opt/

# 4. 在正式服务器加载镜像并启动
ssh root@backendart.com
docker load -i /opt/sanmoo-images.tar
cd /opt && docker compose up -d
```

**特点:**
- ✅ HTTPS + SSL 证书
- ✅ 完整的安全防护规则
- ✅ 域名访问: `https://backendart.com`
- ✅ 离线镜像部署，减轻正式服务器压力
- ✅ 适合资源有限的生产服务器（2核2G）

---

### 3️⃣ Legion内网测试部署 (HTTP, 无SSL)

```bash
# 部署内网测试环境
./deploy.sh local
```

**特点:**
- ✅ HTTP 协议,无需 SSL 证书
- ✅ 简化的安全规则
- ✅ IP 地址访问: `http://localhost`
- ✅ 微信测试号配置
- ✅ 适合内网测试、开发环境

---

## 🔐 服务器连接配置

### 生产服务器
- **域名**: `backendart.com`
- **登录账号**: `root`
- **认证方式**: RSA 公私钥认证
- **项目目录**: `/opt`
- **服务器配置**: 2核 CPU / 2GB 内存

### SSH 登录示例

# 登录生产服务器
ssh -i ~/.ssh/id_rsa root@backendart.com
cd /opt
```

---

## 🚀 首次部署生产服务器

### 步骤一：初始化生产服务器环境

```bash
# 1. 登录生产服务器
ssh -i ~/.ssh/id_rsa root@backendart.com

# 2. 确保生产服务器已安装 Docker 和 Docker Compose
docker --version
docker compose version

# 3. 生产服务器已有独立的 docker-compose.yaml 配置文件
#    配置与内网测试环境不完全一致（如 SSL 证书、域名等）
ls -la /opt/docker-compose.yaml
```

### 步骤二：在 Win11 本地构建应用镜像

```bash
# 在 Win11 本地 PowerShell 或 WSL 终端中构建镜像
cd c:\workspace\sanmoo-blog

# 构建生产环境镜像
./deploy.sh production

# 导出应用镜像到离线包
./deploy.sh export
```

> **说明**: 生产服务器已预装基础镜像（mysql:8.4、redis:latest、getmeili/meilisearch:latest），无需重复导出。

### 步骤三：上传并部署

```bash
# 1. 上传镜像包到生产服务器
scp sanmoo-images.tar root@backendart.com:/opt/

# 2. 在生产服务器加载镜像并启动
ssh -i ~/.ssh/id_rsa root@backendart.com
docker load -i /opt/sanmoo-images.tar
cd /opt && docker compose up -d

# 3. 查看服务状态
docker compose ps
```

---

## 🔧 生产环境更新部署流程

### 步骤一：在 Win11 本地构建镜像

```bash
# 在 Win11 本地 PowerShell 或 WSL 终端中构建镜像
cd c:\workspace\sanmoo-blog

# 执行部署脚本构建生产环境镜像
./deploy.sh production
```

### 步骤二：导出离线镜像包

```bash
# 使用部署脚本导出镜像
./deploy.sh export

# 查看导出文件大小
ls -lh sanmoo-images.tar
```

### 步骤三：上传到生产服务器

```bash
# 使用 scp 上传镜像包到生产服务器 /opt 目录
scp sanmoo-images.tar root@backendart.com:/opt/
```

### 步骤四：在生产服务器加载镜像并启动

```bash
# 登录生产服务器
ssh -i ~/.ssh/id_rsa root@backendart.com

# 加载镜像
docker load -i /opt/sanmoo-images.tar

# 启动/更新容器
cd /opt && docker compose up -d

# 查看容器状态
docker compose ps
```

### 步骤五：清理临时文件

```bash
# 清理测试机上的镜像包（可选）
rm sanmoo-images.tar

# 清理生产服务器上的镜像包（可选）
rm /opt/sanmoo-images.tar
```

---

## 🔧 Win11 本地测试环境部署步骤

### 自动化部署（推荐）

```bash
# 在 Win11 本地 PowerShell 或 WSL 终端中执行
cd c:\workspace\sanmoo-blog

# 执行部署脚本（本地测试环境）
./deploy.sh local
```

### 手动部署

```bash
cd c:\workspace\sanmoo-blog
git pull origin main
docker compose down
NGINX_ENV=local docker compose -f docker-compose.yaml -f docker-compose.local.yaml build --no-cache
NGINX_ENV=local docker compose -f docker-compose.yaml -f docker-compose.local.yaml up -d
```

---

## 📊 查看服务状态

```bash
# 查看所有容器状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f sanmoo-vite
docker compose logs -f sanmoo-server-go
```

---

## 🌐 访问方式

### 生产环境:
- **域名**: `https://backendart.com`
- **API**: `https://backendart.com/api/...`
- **管理后台**: `https://backendart.com/admin`

### Win11 本地测试环境:
- **地址**: `http://localhost`
- **API**: `http://localhost/api/...`
- **登录**: `http://localhost/user/login`
- **管理后台**: `http://localhost/admin`
- **前端开发**: `http://localhost:8000`
- **后端API直连**: `http://localhost:28080/api/...`
- **测试账号**: `admin`
- **测试密码**: `test1234`

---

## ⚙️ 环境变量说明

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `NGINX_ENV` | `production` | 生产环境,启用 HTTPS + SSL |
| `NGINX_ENV` | `local` | 内网测试,仅 HTTP |
| `WX_APPID` | `wx084d5d60b374c2a4` | 微信小程序 AppID (内网测试) |
| `WX_SECRET` | `f5207f4068251d589cc12923acd2d759` | 微信小程序 Secret (内网测试) |

---

## 🔄 切换环境

如果需要从内网测试切换到生产环境:

```bash
# 1. 在测试机构建生产镜像
./deploy.sh production

# 2. 导出镜像包
./deploy.sh export

# 3. 上传并部署到生产服务器
scp sanmoo-images.tar root@backendart.com:/opt/
ssh root@backendart.com "docker load -i /opt/sanmoo-images.tar && cd /opt && docker compose up -d"
```

---

## 🐳 Docker 服务说明

| 服务名 | 镜像 | 端口 | 说明 |
|--------|------|------|------|
| `mysql` | `mysql:8.4` | `3306` | 数据库 |
| `redis` | `redis:latest` | `6379` | 缓存 |
| `meilisearch` | `getmeili/meilisearch:latest` | `7700` | 全文搜索 |
| `sanmoo-server-go` | 自建镜像 | `28080` | 后端 API |
| `sanmoo-vite` | 自建镜像 | `80/443` | 前端 + Nginx |

---

## 📝 配置文件说明

- `docker-compose.yaml` - 内网测试环境基础服务配置
- `docker-compose.local.yaml` - 内网测试环境覆盖配置(HTTP, 微信测试号)
- `deploy.sh` - 自动化部署脚本，支持 production/local/export 三种模式
- 生产服务器 `/opt/docker-compose.yaml` - 生产环境独立配置（含SSL证书等）

---

## 💡 部署注意事项

1. **生产服务器资源限制**: 由于正式服务器仅有2核2G，推荐使用离线镜像部署方式，避免在生产服务器上执行构建操作
2. **数据库数据持久化**: MySQL和Redis数据通过Docker Volume持久化，部署时不会丢失
3. **环境差异**: 生产环境与内网测试环境配置不完全一致，生产服务器使用独立的 docker-compose.yaml
4. **SSL证书**: 生产环境使用HTTPS，SSL证书配置在生产服务器的 docker-compose.yaml 中
5. **离线镜像包**: 仅包含应用服务镜像（sanmoo-server-go、sanmoo-vite），生产服务器已预装基础镜像（mysql:8.4、redis:latest、getmeili/meilisearch:latest）

