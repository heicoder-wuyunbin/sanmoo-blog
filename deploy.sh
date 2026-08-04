#!/bin/bash

set -euo pipefail

REPO_URL="git@github.com:heicoder-wuyunbin/sanmoo-blog.git"
WORK_DIR="/opt/sanmoo-blog"
ROLLBACK_FILE="${WORK_DIR}/.rollback_info"
DISK_WARN_THRESHOLD=80

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
        INFO) echo -e "${BLUE}[${timestamp}] INFO: $*${NC}" ;;
        SUCCESS) echo -e "${GREEN}[${timestamp}] SUCCESS: $*${NC}" ;;
        WARN) echo -e "${YELLOW}[${timestamp}] WARN: $*${NC}" ;;
        ERROR) echo -e "${RED}[${timestamp}] ERROR: $*${NC}" ;;
    esac
    mkdir -p "$WORK_DIR" 2>/dev/null || true
    echo "[$timestamp] $level: $*" >> "${WORK_DIR}/deploy.log" 2>/dev/null || true
}

error_exit() {
    log ERROR "$1"
    exit 1
}

check_disk_usage() {
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    echo "$disk_usage"
}

should_cleanup() {
    local usage=$(check_disk_usage)
    if [ "$usage" -ge "$DISK_WARN_THRESHOLD" ]; then
        log WARN "磁盘使用率 ${usage}% >= ${DISK_WARN_THRESHOLD}%，需要清理"
        return 0
    else
        log INFO "磁盘使用率 ${usage}% < ${DISK_WARN_THRESHOLD}%，跳过自动清理"
        return 1
    fi
}

cleanup_docker_resources() {
    log INFO "开始清理 Docker 资源..."
    
    local dangling_count=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    if [ "$dangling_count" -gt 0 ]; then
        log INFO "清理 ${dangling_count} 个悬停镜像..."
        if timeout 30 docker image prune -f; then
            log SUCCESS "悬停镜像清理完成"
        else
            log WARN "悬停镜像清理超时或失败"
        fi
    else
        log INFO "未检测到悬停镜像"
    fi
    
    log INFO "清理构建缓存..."
    if timeout 30 docker builder prune -a -f; then
        log SUCCESS "构建缓存清理完成"
    else
        log WARN "构建缓存清理超时或失败"
    fi
    
    local stopped_count=$(docker ps -a -f "status=exited" -q 2>/dev/null | wc -l)
    if [ "$stopped_count" -gt 0 ]; then
        log INFO "清理 ${stopped_count} 个停止的容器..."
        if timeout 30 docker container prune -f; then
            log SUCCESS "停止的容器清理完成"
        else
            log WARN "停止的容器清理超时或失败"
        fi
    else
        log INFO "未检测到停止的容器"
    fi
    
    log SUCCESS "Docker 资源清理完成"
}

record_before_pull() {
    local dir=$1
    if [ -d "$dir/.git" ]; then
        echo "$(cd "$dir" && git rev-parse HEAD)"
    else
        echo "__NEW__"
    fi
}

get_file_checksum() {
    local file=$1
    if [ -f "$file" ]; then
        md5sum "$file" | awk '{print $1}'
    else
        echo "__MISSING__"
    fi
}

save_rollback_info() {
    log INFO "保存回滚信息..."
    mkdir -p "$WORK_DIR"
    echo "ROLLBACK_TIME=$(date '+%Y-%m-%d %H:%M:%S')" > "$ROLLBACK_FILE"
    for svc in sanmoo-server-go sanmoo-vite; do
        local img=$(docker images "$svc" -q 2>/dev/null | head -1)
        if [ -n "$img" ]; then
            echo "${svc}_IMAGE=${img}" >> "$ROLLBACK_FILE"
            log INFO "保存 ${svc} 镜像: ${img:0:12}..."
        fi
    done
}

rollback_deployment() {
    if [ ! -f "$ROLLBACK_FILE" ]; then
        error_exit "未找到回滚信息文件"
    fi
    
    log WARN "开始执行回滚..."
    source "$ROLLBACK_FILE"
    
    cd "$WORK_DIR" || error_exit "无法进入工作目录"
    
    for svc in sanmoo-server-go sanmoo-vite; do
        local img_var="${svc}_IMAGE"
        local img="${!img_var}"
        if [ -n "$img" ] && docker images "$img" -q 2>/dev/null | grep -q .; then
            log INFO "回滚 ${svc} 到镜像: ${img:0:12}..."
            docker tag "$img" "${svc}:latest"
            docker compose up -d "$svc"
            log SUCCESS "${svc} 回滚完成"
        else
            log WARN "${svc} 没有可回滚的镜像"
        fi
    done
    
    log SUCCESS "回滚完成"
    exit 0
}

show_status() {
    echo "========================================="
    echo "Sanmoo Blog 服务状态"
    echo "========================================="
    echo ""
    
    if [ -d "$WORK_DIR" ]; then
        cd "$WORK_DIR" || return
        echo "📁 代码版本:"
        echo "   主仓库: $(git rev-parse --short HEAD 2>/dev/null || echo "未知")"
        for sub in sanmoo-mp sanmoo-server-go sanmoo-vite; do
            if [ -d "$sub" ]; then
                cd "$sub"
                echo "   ${sub}: $(git rev-parse --short HEAD 2>/dev/null || echo "未知")"
                cd ..
            fi
        done
        echo ""
    fi
    
    echo "🐳 Docker 服务状态:"
    docker compose ps 2>/dev/null || echo "   Docker Compose 未运行"
    
    echo ""
    echo "💾 磁盘使用情况:"
    df -h / | tail -1
    
    if [ -f "$ROLLBACK_FILE" ]; then
        echo ""
        echo "🔄 回滚信息:"
        cat "$ROLLBACK_FILE"
    fi
}

get_container_status() {
    local container_name=$1
    local status=$(docker inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
    echo "$status"
}

deploy() {
    local DEPLOY_ENV=$1
    START_TIME=$(date +%s)
    
    log INFO "开始部署 Sanmoo Blog (${DEPLOY_ENV})"
    
    if [ ! -d "$WORK_DIR" ]; then
        log INFO "首次部署，克隆仓库..."
        git clone "$REPO_URL" "$WORK_DIR"
    fi
    
    cd "$WORK_DIR" || error_exit "无法进入工作目录"
    
    git config core.fileMode false
    
    MAIN_BEFORE=$(record_before_pull "$WORK_DIR")
    ENV_BEFORE=$(get_file_checksum ".env")
    
    SUBMODULES=("sanmoo-mp" "sanmoo-server-go" "sanmoo-vite")
    declare -A SUB_BEFORE SUB_AFTER DOCKERFILE_BEFORE DOCKERFILE_AFTER
    
    for sub in "${SUBMODULES[@]}"; do
        if [ -d "$sub" ]; then
            SUB_BEFORE["$sub"]=$(record_before_pull "$sub")
            DOCKERFILE_BEFORE["$sub"]=$(get_file_checksum "${sub}/Dockerfile")
        else
            SUB_BEFORE["$sub"]="__NEW__"
            DOCKERFILE_BEFORE["$sub"]="__MISSING__"
        fi
    done
    
    log INFO "拉取最新代码..."
    git pull --rebase --autostash origin main
    MAIN_AFTER=$(git rev-parse HEAD)
    ENV_AFTER=$(get_file_checksum ".env")
    
    log INFO "更新子模块..."
    git submodule update --init --recursive --remote --merge
    
    for sub in "${SUBMODULES[@]}"; do
        if [ -d "$sub" ]; then
            cd "$sub"
            git checkout main 2>/dev/null || git checkout -b main origin/main 2>/dev/null || true
            git pull origin main
            SUB_AFTER["$sub"]=$(git rev-parse HEAD)
            DOCKERFILE_AFTER["$sub"]=$(get_file_checksum "Dockerfile")
            cd ..
        else
            SUB_AFTER["$sub"]="__NEW__"
            DOCKERFILE_AFTER["$sub"]="__MISSING__"
        fi
    done
    
    VITE_CHANGED=false
    SERVER_CHANGED=false
    MAIN_CONFIG_CHANGED=false
    ENV_CHANGED=false
    
    for sub in "${SUBMODULES[@]}"; do
        if [ "${SUB_BEFORE[$sub]}" != "${SUB_AFTER[$sub]}" ]; then
            log INFO "${sub} 代码变更: ${SUB_BEFORE[$sub]:0:7} -> ${SUB_AFTER[$sub]:0:7}"
            case "$sub" in
                "sanmoo-vite") VITE_CHANGED=true ;;
                "sanmoo-server-go") SERVER_CHANGED=true ;;
            esac
        fi
        if [ "${DOCKERFILE_BEFORE[$sub]}" != "${DOCKERFILE_AFTER[$sub]}" ]; then
            log INFO "${sub} Dockerfile 变更"
            case "$sub" in
                "sanmoo-vite") VITE_CHANGED=true ;;
                "sanmoo-server-go") SERVER_CHANGED=true ;;
            esac
        fi
    done
    
    if [ "$ENV_BEFORE" != "$ENV_AFTER" ]; then
        log INFO ".env 文件变更"
        ENV_CHANGED=true
    fi
    
    if [ "$MAIN_BEFORE" != "$MAIN_AFTER" ]; then
        log INFO "主仓库变更: ${MAIN_BEFORE:0:7} -> ${MAIN_AFTER:0:7}"
        if git diff --name-only "$MAIN_BEFORE" "$MAIN_AFTER" 2>/dev/null | grep -qE "docker-compose"; then
            MAIN_CONFIG_CHANGED=true
            log INFO "检测到 docker-compose 配置变更"
        fi
    fi
    
    if [ "$VITE_CHANGED" = false ] && [ "$SERVER_CHANGED" = false ] && [ "$MAIN_CONFIG_CHANGED" = false ] && [ "$ENV_CHANGED" = false ]; then
        log SUCCESS "所有服务已是最新，无需部署"
        END_TIME=$(date +%s)
        log INFO "总耗时: $(( (END_TIME - START_TIME) / 60 ))分$(( (END_TIME - START_TIME) % 60 ))秒"
        exit 0
    fi
    
    REBUILD_SERVICES=""
    RESTART_ONLY_SERVICES=""
    
    if [ "$VITE_CHANGED" = true ]; then
        REBUILD_SERVICES="$REBUILD_SERVICES sanmoo-vite"
    elif [ "$MAIN_CONFIG_CHANGED" = true ] || [ "$ENV_CHANGED" = true ]; then
        RESTART_ONLY_SERVICES="$RESTART_ONLY_SERVICES sanmoo-vite"
    fi
    
    if [ "$SERVER_CHANGED" = true ]; then
        REBUILD_SERVICES="$REBUILD_SERVICES sanmoo-server-go"
    elif [ "$MAIN_CONFIG_CHANGED" = true ] || [ "$ENV_CHANGED" = true ]; then
        RESTART_ONLY_SERVICES="$RESTART_ONLY_SERVICES sanmoo-server-go"
    fi
    
    log INFO "需要重建的服务: ${REBUILD_SERVICES:-无}"
    log INFO "只需重启的服务: ${RESTART_ONLY_SERVICES:-无}"
    
    if [ -n "$REBUILD_SERVICES" ]; then
        save_rollback_info
        
        if should_cleanup; then
            cleanup_docker_resources
        fi
        
        for svc in $REBUILD_SERVICES; do
            log INFO "停止 ${svc}..."
            docker compose stop "$svc" 2>/dev/null || true
            docker compose rm -f "$svc" 2>/dev/null || true
        done
        
        log INFO "开始构建镜像..."
        local build_flags=""
        if [ "$VITE_CHANGED" = true ] || [ "$SERVER_CHANGED" = true ]; then
            build_flags="--no-cache"
        fi
        
        if [ "$DEPLOY_ENV" = "local" ]; then
            docker compose -f docker-compose.yaml -f docker-compose.local.yaml build $build_flags $REBUILD_SERVICES
        else
            docker compose build $build_flags $REBUILD_SERVICES
        fi
        log SUCCESS "镜像构建完成"
    fi
    
    log INFO "启动/重启服务..."
    local all_services="$REBUILD_SERVICES $RESTART_ONLY_SERVICES"
    if [ "$DEPLOY_ENV" = "local" ]; then
        docker compose -f docker-compose.yaml -f docker-compose.local.yaml up -d $all_services
    else
        docker compose up -d $all_services
    fi
    log SUCCESS "服务已启动"
    
    log INFO "等待服务启动..."
    sleep 10
    
    log INFO "检查服务状态..."
    local all_healthy=true
    for svc in $all_services; do
        local status=$(get_container_status "$svc")
        if [ "$status" != "running" ]; then
            log ERROR "${svc} 启动失败，状态: ${status}"
            all_healthy=false
        else
            log SUCCESS "${svc} 运行正常"
        fi
    done
    
    docker compose ps
    
    if [ "$all_healthy" = false ]; then
        log WARN "部分服务启动异常，可执行 ./deploy.sh rollback 回滚"
    fi
    
    log SUCCESS "部署完成"
    
    if [ "$DEPLOY_ENV" = "local" ]; then
        log INFO "访问地址: http://$(hostname -I | awk '{print $1}')"
    else
        log INFO "访问地址: https://backendart.com"
    fi
    
    END_TIME=$(date +%s)
    log INFO "总耗时: $(( (END_TIME - START_TIME) / 60 ))分$(( (END_TIME - START_TIME) % 60 ))秒"
}

export_images() {
    START_TIME=$(date +%s)
    log INFO "开始导出离线镜像包"
    
    cd "$WORK_DIR" 2>/dev/null || true
    
    APP_IMAGES="sanmoo-server-go sanmoo-vite"
    MISSING_IMAGES=""
    
    for img in $APP_IMAGES; do
        if ! docker images | grep -q "^$img "; then
            MISSING_IMAGES="$MISSING_IMAGES $img"
        fi
    done
    
    if [ -n "$MISSING_IMAGES" ]; then
        error_exit "以下应用镜像不存在: $MISSING_IMAGES，请先执行 ./deploy.sh production"
    fi
    
    OUTPUT_FILE="sanmoo-images.tar"
    if [ -f "$OUTPUT_FILE" ]; then
        rm "$OUTPUT_FILE"
    fi
    
    docker save $APP_IMAGES -o "$OUTPUT_FILE"
    
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | awk '{print $1}')
        log SUCCESS "镜像包导出成功: $OUTPUT_FILE ($FILE_SIZE)"
        echo ""
        echo "📌 离线镜像包: $OUTPUT_FILE"
        echo ""
        echo "上传到生产服务器:"
        echo "  scp $OUTPUT_FILE root@backendart.com:/opt/"
        echo ""
        echo "在生产服务器执行:"
        echo "  docker load -i /opt/$OUTPUT_FILE"
        echo "  cd /opt/sanmoo-blog && docker compose up -d"
    else
        error_exit "镜像包导出失败"
    fi
    
    END_TIME=$(date +%s)
    log INFO "总耗时: $(( (END_TIME - START_TIME) / 60 ))分$(( (END_TIME - START_TIME) % 60 ))秒"
}

case "${1:-production}" in
    production)
        deploy "production"
        ;;
    local)
        deploy "local"
        ;;
    export)
        export_images
        ;;
    cleanup)
        cleanup_docker_resources
        ;;
    status)
        show_status
        ;;
    rollback)
        rollback_deployment
        ;;
    *)
        echo "用法: ./deploy.sh [production|local|export|cleanup|status|rollback]"
        echo "  production - 生产环境(HTTPS + SSL)"
        echo "  local      - 本地测试环境(HTTP,无SSL)"
        echo "  export     - 导出离线镜像包"
        echo "  cleanup    - 清理 Docker 资源"
        echo "  status     - 查看服务状态"
        echo "  rollback   - 回滚到上一个版本"
        exit 1
        ;;
esac