#!/bin/bash

set -euo pipefail

# ============================================================
# Sanmoo Blog - Mac 离线构建部署脚本
# 平台: ARM64 (Apple Silicon Mac) -> AMD64 (Linux 服务器)
# 功能: 本地编译 Go/前端 → 构建 linux/amd64 Docker 镜像 → 导出 tar
# ============================================================

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${WORK_DIR}/offline-packages"
GO_MODULE_DIR="${WORK_DIR}/sanmoo-server-go"
VITE_DIR="${WORK_DIR}/sanmoo-vite"

# 需要导出的应用镜像
APP_IMAGES=("sanmoo-server-go:latest" "sanmoo-vite:latest")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level=$1
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$level" in
        INFO)  echo -e "${BLUE}[${timestamp}] INFO: $*${NC}" ;;
        SUCCESS) echo -e "${GREEN}[${timestamp}] SUCCESS: $*${NC}" ;;
        WARN)  echo -e "${YELLOW}[${timestamp}] WARN: $*${NC}" ;;
        ERROR) echo -e "${RED}[${timestamp}] ERROR: $*${NC}" ;;
    esac
}

error_exit() {
    log ERROR "$1"
    exit 1
}

# ============================================================
# 确保 Docker buildx 可用
# 场景: Colima 用户可能没有 Docker Desktop，需要手动下载 buildx 插件
#       Docker Desktop 用户如果符号链接损坏，也会自动修复
# ============================================================
ensure_buildx() {
    # 如果 buildx 已经可用，直接返回
    if docker buildx version &> /dev/null; then
        log INFO "  Buildx  : $(docker buildx version | head -1)"
        return 0
    fi

    # 检查是否是损坏的符号链接（Docker Desktop 未安装）
    local PLUGIN_PATH="$HOME/.docker/cli-plugins/docker-buildx"
    if [ -L "$PLUGIN_PATH" ] && [ ! -e "$PLUGIN_PATH" ]; then
        log WARN "检测到 Docker Desktop 残留的 buildx 符号链接，正在修复..."
        rm -f "$PLUGIN_PATH"
    fi

    # 下载独立的 buildx 二进制文件
    log INFO "正在下载 Docker buildx 插件..."
    local BUILDX_VERSION="v0.22.0"
    local BUILDX_URL="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.darwin-arm64"

    mkdir -p "$HOME/.docker/cli-plugins"

    if curl -fsSL "$BUILDX_URL" -o "$PLUGIN_PATH"; then
        chmod +x "$PLUGIN_PATH"
        if docker buildx version &> /dev/null; then
            log INFO "  Buildx  : $(docker buildx version | head -1)"
            log SUCCESS "Docker buildx 安装成功"
            return 0
        fi
    fi

    error_exit "无法安装 Docker buildx。请手动下载: ${BUILDX_URL} → ${PLUGIN_PATH}"
}

# ============================================================
# 检查本地环境
# ============================================================
check_prerequisites() {
    log INFO "检查本地开发环境..."

    if ! command -v go &> /dev/null; then
        error_exit "未找到 go，请先安装 Go"
    fi
    log INFO "  Go      : $(go version)"

    if ! command -v pnpm &> /dev/null; then
        error_exit "未找到 pnpm，请先安装 pnpm"
    fi
    log INFO "  pnpm    : $(pnpm -v)"

    if ! command -v node &> /dev/null; then
        error_exit "未找到 node，请先安装 Node.js"
    fi
    log INFO "  Node    : $(node --version)"

    if ! command -v docker &> /dev/null; then
        error_exit "未找到 docker，请先安装 Docker Desktop"
    fi
    log INFO "  Docker  : $(docker --version)"

    # 确保 buildx 可用（自动修复损坏的 Docker Desktop 符号链接）
    ensure_buildx

    log SUCCESS "本地环境检查通过 (ARM64 Mac)"
}

# ============================================================
# 编译 Go 后端 (linux/amd64)
# ============================================================
build_go_backend() {
    log INFO "交叉编译 Go 后端 (darwin/arm64 -> linux/amd64)..."

    cd "$GO_MODULE_DIR"

    # 检查必要文件
    if [ ! -f "cmd/server/main.go" ]; then
        error_exit "未找到 cmd/server/main.go"
    fi
    if [ ! -f "ca-certificates.crt" ]; then
        error_exit "未找到 ca-certificates.crt（SSL 证书文件）"
    fi
    if [ ! -f "application.properties" ]; then
        error_exit "未找到 application.properties"
    fi

    # 本地交叉编译（纯 Go，无需 CGO，速度极快）
    log INFO "  编译 server..."
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-w -s" -o server cmd/server/main.go

    log INFO "  编译 healthcheck..."
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-w -s" -o healthcheck healthcheck.go

    log SUCCESS "Go 二进制编译完成"
    file server healthcheck

    # 构建最小化 Docker 镜像 (FROM scratch，无需模拟器)
    log INFO "构建 Go 后端 Docker 镜像 (linux/amd64)..."

    cat > Dockerfile.mac << 'DOCKERFILE_EOF'
FROM scratch
COPY ca-certificates.crt /etc/ssl/certs/
COPY server /app/server
COPY healthcheck /app/healthcheck
COPY application.properties /app/application.properties
WORKDIR /app
ENV APP_ENV=production
EXPOSE 28080
ENTRYPOINT ["/app/server"]
DOCKERFILE_EOF

    docker build --platform linux/amd64 -t sanmoo-server-go:latest -f Dockerfile.mac .

    # 清理临时文件
    rm -f Dockerfile.mac server healthcheck

    cd "$WORK_DIR"
    log SUCCESS "Go 后端镜像构建完成: sanmoo-server-go:latest"
}

# ============================================================
# 编译前端 (pnpm build) + 构建 Docker 镜像
# ============================================================
build_frontend() {
    log INFO "构建前端项目..."

    cd "$VITE_DIR"

    # 检查 SSL 证书
    if [ ! -f "fullchain.pem" ]; then
        error_exit "未找到 fullchain.pem（SSL 证书）"
    fi
    if [ ! -f "certkey.pem" ]; then
        error_exit "未找到 certkey.pem（SSL 私钥）"
    fi
    if [ ! -f "nginx-frontend.conf" ]; then
        error_exit "未找到 nginx-frontend.conf"
    fi

    # 本地安装依赖 + 构建（纯 ARM 原生，速度极快）
    log INFO "  pnpm install..."
    pnpm install --no-frozen-lockfile

    log INFO "  pnpm build..."
    pnpm run build

    if [ ! -d "dist" ]; then
        error_exit "前端构建失败，未生成 dist 目录"
    fi

    log SUCCESS "前端构建完成"

    # 构建 Docker 镜像（需要拉取 amd64 nginx 镜像，通过 Rosetta 2 运行）
    log INFO "构建前端 Docker 镜像 (linux/amd64, 生产环境 HTTPS)..."

    cat > Dockerfile.mac << 'DOCKERFILE_EOF'
FROM nginx:latest
COPY dist /usr/share/nginx/html
COPY fullchain.pem /etc/nginx/ssl/fullchain.pem
COPY certkey.pem /etc/nginx/ssl/certkey.pem
COPY nginx-frontend.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE_EOF

    # .dockerignore 排除了 dist，但 Dockerfile.mac 需要 COPY dist
    # 临时移除 .dockerignore，构建完成后恢复
    if [ -f .dockerignore ]; then
        mv .dockerignore .dockerignore.bak
    fi

    docker build --platform linux/amd64 -t sanmoo-vite:latest -f Dockerfile.mac .

    # 恢复 .dockerignore 并清理临时文件
    if [ -f .dockerignore.bak ]; then
        mv .dockerignore.bak .dockerignore
    fi
    rm -f Dockerfile.mac

    cd "$WORK_DIR"
    log SUCCESS "前端镜像构建完成: sanmoo-vite:latest"
}

# ============================================================
# 导出应用镜像为 tar
# ============================================================
export_app_images() {
    log INFO "导出应用镜像为离线包..."

    mkdir -p "$OUTPUT_DIR"

    local APP_TAR="${OUTPUT_DIR}/sanmoo-app-images.tar"

    if [ -f "$APP_TAR" ]; then
        rm "$APP_TAR"
    fi

    # 验证镜像存在
    for img in "${APP_IMAGES[@]}"; do
        if ! docker image inspect "$img" &> /dev/null; then
            error_exit "镜像 ${img} 不存在，请先执行构建"
        fi
    done

    log INFO "  保存 ${APP_IMAGES[*]} ..."
    docker save "${APP_IMAGES[@]}" -o "$APP_TAR"

    if [ -f "$APP_TAR" ]; then
        local FILE_SIZE
        FILE_SIZE=$(du -h "$APP_TAR" | awk '{print $1}')
        log SUCCESS "应用镜像包导出成功: $APP_TAR ($FILE_SIZE)"
    else
        error_exit "应用镜像包导出失败"
    fi
}

# ============================================================
# 打印部署说明
# ============================================================
print_instructions() {
    local APP_TAR="${OUTPUT_DIR}/sanmoo-app-images.tar"

    echo ""
    echo "========================================="
    echo -e "${GREEN}  离线镜像包已准备就绪${NC}"
    echo "========================================="
    echo ""
    echo "离线包位置: ${OUTPUT_DIR}/"
    ls -lh "${OUTPUT_DIR}/"*.tar 2>/dev/null || echo "  (无 tar 文件)"
    echo ""
    echo "========================================="
    echo -e "${YELLOW}  线上部署步骤 (AMD64 Ubuntu 服务器)${NC}"
    echo "========================================="
    echo ""
    echo "1. 上传镜像包到服务器:"
    echo "   scp ${APP_TAR} root@backendart.com:/opt/"
    echo ""
    echo "2. SSH 到服务器，加载镜像:"
    echo "   ssh root@backendart.com"
    echo "   docker load -i /opt/sanmoo-app-images.tar"
    echo ""
    echo "3. 启动/更新服务:"
    echo "   cd /opt/sanmoo-blog"
    echo "   docker compose up -d sanmoo-server-go sanmoo-vite"
    echo ""
    echo "4. 检查服务状态:"
    echo "   docker compose ps"
    echo "   docker compose logs -f sanmoo-server-go"
    echo "   docker compose logs -f sanmoo-vite"
    echo ""
    echo "========================================="
    echo -e "${YELLOW}  注意事项${NC}"
    echo "========================================="
    echo ""
    echo "• 前端使用 nginx-frontend.conf (HTTPS + SSL)"
    echo "• SSL 证书已打包在镜像中，无需额外配置"
    echo "• 基础设施镜像 (mysql/redis/meilisearch) 由线上 deploy.sh 自行拉取"
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    local START_TIME
    START_TIME=$(date +%s)

    echo ""
    echo "========================================="
    echo "  Sanmoo Blog - Mac 离线构建部署脚本"
    echo "  平台: ARM64 (Mac) -> AMD64 (Linux)"
    echo "========================================="
    echo ""

    local MODE="${1:-full}"

    case "$MODE" in
        full|app-only)
            check_prerequisites
            build_go_backend
            build_frontend
            export_app_images
            print_instructions
            ;;
        go-only)
            check_prerequisites
            build_go_backend
            export_app_images
            ;;
        vite-only)
            check_prerequisites
            build_frontend
            export_app_images
            ;;
        help|--help|-h)
            echo "用法: ./deploy-mac.sh [full|go-only|vite-only|help]"
            echo ""
            echo "  full       - 编译 Go + 前端，构建镜像，导出 tar（默认）"
            echo "  go-only    - 仅编译 Go 后端并导出镜像"
            echo "  vite-only  - 仅编译前端并导出镜像"
            echo "  help       - 显示帮助"
            exit 0
            ;;
        *)
            error_exit "未知模式: $MODE。使用 ./deploy-mac.sh help 查看帮助"
            ;;
    esac

    local END_TIME
    END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    log SUCCESS "全部完成！总耗时: $((DURATION / 60))分$((DURATION % 60))秒"
}

main "$@"