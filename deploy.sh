#!/bin/bash

# Sanmoo Blog 部署脚本
set -e

# ===== 配置区域（按需修改）=====
REPO_URL="git@gitee.com:wuyunbin084math/sanmoo-blog.git"   # 替换为你的仓库地址
WORK_DIR="/opt/sanmoo-blog"                          # 代码存放目录
# ==============================

# 默认环境为 production
DEPLOY_ENV=${1:-production}

# 验证参数
if [[ "$DEPLOY_ENV" != "production" && "$DEPLOY_ENV" != "local" && "$DEPLOY_ENV" != "export" ]]; then
    echo "错误: 无效的环境参数"
    echo "用法: ./deploy.sh [production|local|export]"
    echo "  production - 生产环境(HTTPS + SSL)"
    echo "  local      - 本地测试环境(HTTP,无SSL)"
    echo "  export     - 导出离线镜像包用于生产服务器部署"
    exit 1
fi

# 如果是导出模式，直接跳转到导出逻辑
if [[ "$DEPLOY_ENV" == "export" ]]; then
    echo "========================================="
    echo "开始导出离线镜像包"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    START_TIME=$(date +%s)

    cd "$WORK_DIR" 2>/dev/null || true

    echo ""
    echo "步骤 1: 检查应用镜像是否存在..."
    APP_IMAGES="sanmoo-server-go sanmoo-vite"
    MISSING_IMAGES=""

    for img in $APP_IMAGES; do
        if ! docker images | grep -q "^$img "; then
            MISSING_IMAGES="$MISSING_IMAGES $img"
        fi
    done

    if [ -n "$MISSING_IMAGES" ]; then
        echo "❌ 以下应用镜像不存在:"
        echo "   $MISSING_IMAGES"
        echo ""
        echo "请先执行构建:"
        echo "  ./deploy.sh production"
        exit 1
    fi
    echo "✓ 应用镜像已就绪"

    echo ""
    echo "步骤 2: 导出镜像到 tar 文件..."
    OUTPUT_FILE="sanmoo-images.tar"
    if [ -f "$OUTPUT_FILE" ]; then
        echo "  移除旧的镜像包..."
        rm "$OUTPUT_FILE"
    fi

    echo "  正在导出应用镜像..."
    docker save $APP_IMAGES -o "$OUTPUT_FILE"

    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | awk '{print $1}')
        echo "  ✓ 镜像包导出成功: $OUTPUT_FILE ($FILE_SIZE)"
    else
        echo "  ❌ 镜像包导出失败"
        exit 1
    fi

    echo ""
    echo "========================================="
    echo "导出完成！"
    echo "========================================="
    echo ""
    echo "📌 离线镜像包: $OUTPUT_FILE"
    echo ""
    echo "接下来上传到生产服务器:"
    echo "  scp $OUTPUT_FILE root@backendart.com:/opt/"
    echo ""
    echo "在生产服务器执行:"
    echo "  docker load -i /opt/$OUTPUT_FILE"
    echo "  cd /opt/sanmoo-blog && docker compose up -d"

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    echo "⏱️  执行完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "⏱️  总耗时: $((ELAPSED / 60))分$((ELAPSED % 60))秒"
    exit 0
fi

echo "========================================="
echo "开始部署 Sanmoo Blog"
echo "部署环境: $DEPLOY_ENV"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
START_TIME=$(date +%s)

# 1. 拉取最新代码
echo ""
echo "步骤 1: 拉取最新代码..."

# 记录拉取前的 commit hash，用于判断是否有新代码
record_before_pull() {
    local dir=$1
    local label=$2
    if [ -d "$dir/.git" ]; then
        echo "$(cd "$dir" && git rev-parse HEAD)"
    else
        echo "__NEW__"
    fi
}

if [ -d "$WORK_DIR" ]; then
    echo "代码目录已存在，拉取最新代码..."
    MAIN_BEFORE=$(record_before_pull "$WORK_DIR" "主仓库")
    cd "$WORK_DIR"
    # 忽略文件权限变更，避免 chmod +x 被误判为修改
    git config core.fileMode false
    git pull --rebase --autostash origin main
    MAIN_AFTER=$(git rev-parse HEAD)
else
    echo "首次部署，克隆仓库..."
    MAIN_BEFORE="__NEW__"
    git clone "$REPO_URL" "$WORK_DIR"
    cd "$WORK_DIR"
    MAIN_AFTER=$(git rev-parse HEAD)
fi
echo "✓ 主仓库代码更新完成"

# 记录子模块拉取前的状态
declare -A SUB_BEFORE SUB_AFTER
SUBMODULES=("sanmoo-mp" "sanmoo-server-go" "sanmoo-vite")
for submodule in "${SUBMODULES[@]}"; do
    if [ -d "$submodule" ]; then
        SUB_BEFORE["$submodule"]=$(record_before_pull "$submodule" "$submodule")
    else
        SUB_BEFORE["$submodule"]="__NEW__"
    fi
done

# 初始化并更新所有子模块，确保跟踪 main 分支
echo "正在更新子模块到 main 分支最新版本..."
git submodule update --init --recursive --remote --merge
echo "✓ 子模块更新完成"

# 确保每个子模块都在 main 分支
echo "验证子模块分支状态..."
for submodule in "${SUBMODULES[@]}"; do
    if [ -d "$submodule" ]; then
        cd "$submodule"
        # 切换到 main 分支
        git checkout main 2>/dev/null || git checkout -b main origin/main 2>/dev/null || true
        # 拉取最新代码
        git pull origin main
        SUB_AFTER["$submodule"]=$(git rev-parse HEAD)
        echo "  ✓ $submodule: ${SUB_AFTER[$submodule]:0:7}"
        cd ..
    fi
done
echo "✓ 所有子模块已同步到 main 分支最新版本"

# 判断各子模块是否有代码变更
VITE_CHANGED=false
SERVER_CHANGED=false
MAIN_CONFIG_CHANGED=false

for submodule in "${SUBMODULES[@]}"; do
    if [ "${SUB_BEFORE[$submodule]}" != "${SUB_AFTER[$submodule]}" ]; then
        echo "→ $submodule 有更新: ${SUB_BEFORE[$submodule]:0:7} -> ${SUB_AFTER[$submodule]:0:7}"
        case "$submodule" in
            "sanmoo-vite") VITE_CHANGED=true ;;
            "sanmoo-server-go") SERVER_CHANGED=true ;;
        esac
    fi
done

# 检查主仓库 docker-compose 配置是否有变更
if [ "$MAIN_BEFORE" != "$MAIN_AFTER" ]; then
    echo "→ 主仓库有更新: ${MAIN_BEFORE:0:7} -> ${MAIN_AFTER:0:7}"
    if git diff --name-only "$MAIN_BEFORE" "$MAIN_AFTER" 2>/dev/null | grep -qE "docker-compose|Dockerfile"; then
        MAIN_CONFIG_CHANGED=true
        echo "→ 检测到 docker-compose/Dockerfile 配置变更，将重建应用服务"
    fi
fi

# 如果没有任何应用服务需要更新，直接退出
if [ "$VITE_CHANGED" = false ] && [ "$SERVER_CHANGED" = false ] && [ "$MAIN_CONFIG_CHANGED" = false ]; then
    echo ""
    echo "========================================="
    echo "所有应用服务已是最新，无需重新部署"
    echo "========================================="
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    echo "⏱️  执行完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "⏱️  总耗时: $((ELAPSED / 60))分$((ELAPSED % 60))秒"
    exit 0
fi

echo "→ 检测到代码变更，继续部署..."

# 确定需要重建的服务列表
REBUILD_SERVICES=""
if [ "$VITE_CHANGED" = true ] || [ "$MAIN_CONFIG_CHANGED" = true ]; then
    REBUILD_SERVICES="$REBUILD_SERVICES sanmoo-vite"
fi
if [ "$SERVER_CHANGED" = true ] || [ "$MAIN_CONFIG_CHANGED" = true ]; then
    REBUILD_SERVICES="$REBUILD_SERVICES sanmoo-server-go"
fi
echo "需要重建的服务:$REBUILD_SERVICES"

# 2. 停止需要更新的应用服务（不影响 mysql/redis/meilisearch）
echo ""
echo "步骤 2: 停止需要更新的应用服务..."
for svc in $REBUILD_SERVICES; do
    echo "  停止并移除 $svc..."
    docker compose stop "$svc" 2>/dev/null || true
    docker compose rm -f "$svc" 2>/dev/null || true
done
echo "✓ 目标服务已停止"

# 3. 清理未使用资源释放磁盘空间
echo ""
echo "步骤 3: 清理悬停镜像..."
DANGLING_COUNT=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
if [ "$DANGLING_COUNT" -gt 0 ]; then
    echo "  检测到 $DANGLING_COUNT 个悬停镜像，正在清理..."
    if timeout 30 docker image prune -f; then
        echo "  ✓ 悬停镜像清理完成"
    else
        echo "  ⚠️  悬停镜像清理超时或失败，跳过继续部署"
    fi
else
    echo "  未检测到悬停镜像，跳过清理"
fi

echo ""
echo "步骤 4: 清理构建缓存..."
if timeout 30 docker builder prune -a -f; then
    echo "  ✓ 构建缓存清理完成"
else
    echo "  ⚠️  构建缓存清理超时或失败，跳过继续部署"
fi

# 5. 重新构建变更的服务（无缓存）
echo ""
echo "步骤 5: 重新构建镜像（无缓存）:$REBUILD_SERVICES"
if [ "$DEPLOY_ENV" = "local" ]; then
    echo "使用本地环境配置 (HTTP, 无SSL)"
    docker compose -f docker-compose.yaml -f docker-compose.local.yaml build --no-cache $REBUILD_SERVICES
else
    echo "使用生产环境配置 (HTTPS + SSL)"
    docker compose build --no-cache $REBUILD_SERVICES
fi
echo "✓ 镜像构建完成"

# 6. 启动变更的服务
echo ""
echo "步骤 6: 启动变更的服务..."
if [ "$DEPLOY_ENV" = "local" ]; then
    docker compose -f docker-compose.yaml -f docker-compose.local.yaml up -d $REBUILD_SERVICES
else
    docker compose up -d $REBUILD_SERVICES
fi
echo "✓ 服务已启动"

# 7. 检查服务状态
echo ""
echo "步骤 7: 检查服务状态..."
sleep 5
docker compose ps

# 8. 显示访问信息
echo ""
echo "========================================="
echo "部署完成！"
echo "========================================="
echo ""
if [ "$DEPLOY_ENV" = "local" ]; then
    echo "📌 本地测试环境 (HTTP):"
    echo "   访问地址: http://$(hostname -I | awk '{print $1}')"
    echo "   或: http://localhost"
    echo ""
    echo "⚠️  注意: 本地环境不使用 SSL,仅用于内网测试"
else
    echo "📌 生产环境 (HTTPS):"
    echo "   访问地址: https://backendart.com"
    echo ""
    echo "✅ 已启用 SSL 证书和安全防护"
fi
echo ""
echo "查看日志: docker compose logs -f"
echo "查看状态: docker compose ps"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo ""
echo "⏱️  执行完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "⏱️  总耗时: $((ELAPSED / 60))分$((ELAPSED % 60))秒"
