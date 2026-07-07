# Sanmoo Blog 部署指南

## 📋 快速开始

### 0️⃣ MacBook Pro本地开发环境 (MacBook Pro + Homebrew)

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

**特点:**
- ✅ 本地原生运行，性能最佳
- ✅ 适合日常开发调试
- ✅ 使用 brew services 管理服务启停
- ✅ 数据库密码统一为 root

---

### 1️⃣ 生产环境部署 (HTTPS + SSL)

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

### 2️⃣ Legion内网测试部署 (HTTP, 无SSL)

```bash
# 部署内网测试环境
./deploy.sh local
```

**特点:**
- ✅ HTTP 协议,无需 SSL 证书
- ✅ 简化的安全规则
- ✅ IP 地址访问: `http://192.168.168.130`
- ✅ 微信测试号配置
- ✅ 适合内网测试、开发环境

---

## 🔐 服务器连接配置

### 内网测试服务器
- **IP地址**: `192.168.168.130`
- **登录账号**: `root`
- **认证方式**: RSA 公私钥认证
- **项目目录**: `/opt/sanmoo-blog`

### 生产服务器
- **域名**: `backendart.com`
- **登录账号**: `root`
- **认证方式**: RSA 公私钥认证
- **项目目录**: `/opt`
- **服务器配置**: 2核 CPU / 2GB 内存

### SSH 登录示例

```bash
# 登录内网测试服务器
ssh -i ~/.ssh/id_rsa root@192.168.168.130
cd /opt/sanmoo-blog

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

### 步骤二：在legion测试机构建应用镜像

```bash
# 登录测试机
ssh -i ~/.ssh/id_rsa root@192.168.168.130
cd /opt/sanmoo-blog

# 构建应用镜像（测试环境）
./deploy.sh local

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

### 步骤一：在测试机构建镜像

```bash
# 登录测试机
ssh -i ~/.ssh/id_rsa root@192.168.168.130
cd /opt/sanmoo-blog

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

## 🔧 内网测试环境部署步骤

### 自动化部署（推荐）

```bash
# 登录测试机
ssh -i ~/.ssh/id_rsa root@192.168.168.130
cd /opt/sanmoo-blog

# 执行部署脚本
./deploy.sh local
```

### 手动部署

```bash
cd /opt/sanmoo-blog
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

### 内网测试环境:
- **IP地址**: `http://192.168.168.130`
- **API**: `http://192.168.168.130/api/...`
- **管理后台**: `http://192.168.168.130/admin`
- **后端API直连**: `http://192.168.168.130:28080/api/...`
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

